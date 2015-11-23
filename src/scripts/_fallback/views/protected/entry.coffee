"use strict"

helpers = require "common/helpers.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.DocumentNoEntry extends Marionette.ItemView

      template: "protected/no_entry"

    class App.Views.Protected.DocumentEntryItem extends Marionette.ItemView

      template: "protected/entry_item"

      className: ->
        className = "queryBuilder__item _linkDisabled"
        className += " _linkNo" if @model.collection?.section
        className

      attributes: ->
        "data-content": @model.t "global.and"

      ui:
        QUANTITY_THRESHOLD       : "[name=QUANTITY_THRESHOLD]"
        DETECT_FILLED_FORM       : "[name^=DETECT_FILLED_FORM]"
        FINGERPRINT_CONDITION_ID : "[name=FINGERPRINT_CONDITION_ID]"
        labelRadio               : "[data-ui=labelRadio]"

      templateHelpers: ->
        type = @model.get 'ENTRY_TYPE'
        t  = @model.get('content').TYPE

        type = 'stamp' if t is 'stamp'
        type = "graphic" if t is "homography" or t is "classifier"

        @can = helpers.can { type: 'document', action: 'edit' }

        can     : @can
        type    : type
        viewId  : @cid
        getName : =>
          content = @model.get 'content'

          return content.DISPLAY_NAME if content
          App.t "protected.document.entry_deleted"

      events:
        'click [data-toolbar-action=deleteEntry]': ->
          @model.collection.remove @model

      onShow: ->
        return unless @can

        model = @model
        @ui.QUANTITY_THRESHOLD
        .on 'keypress', (e) ->
          if e.currentTarget.value.length >= 2 or e.charCode < 48 or e.charCode > 57
            e.preventDefault()
        .on 'change', (e) ->
          # TODO: выпилить, когда будет корректная реализация ошибок на бекенде
          if model.get('ENTRY_TYPE') is 'form' and @value and @value < 100 and @value > 0
            model.set 'QUANTITY_THRESHOLD', @value
          else if model.get('ENTRY_TYPE') is 'text_object' and @value and @value < 21 and @value > 0
            model.set 'QUANTITY_THRESHOLD', @value
          else if +@value > e.currentTarget.max
            @value = e.currentTarget.max
          else if +@value < e.currentTarget.min
            @value = e.currentTarget.min
          else
            @value = model.get 'QUANTITY_THRESHOLD'

        @ui.DETECT_FILLED_FORM.on 'change', (e) =>
          type  = @model.get 'ENTRY_TYPE'
          value = e.currentTarget.value
          label = App.t "entry.table.QUANTITY_THRESHOLD", context: "condition_#{type}_#{value}"
          @ui.labelRadio.text label
          model.set 'DETECT_FILLED_FORM', +value

        @ui.FINGERPRINT_CONDITION_ID
        .select2 minimumResultsForSearch: 10
        .select2 'val', @model.get('FINGERPRINT_CONDITION_ID')
        .on 'change', (e) =>
          @model.set 'FINGERPRINT_CONDITION_ID', e.val
          condition = _.find _this.model.attributes.content.conditions, CONDITION_ID: e.val
          @model.set 'et_condition', condition if condition

    class App.Views.Protected.DocumentEntry extends Marionette.CompositeView

      template: "protected/entry"

      templateHelpers: -> entries: @options.entries

      childViewContainer: '[data-ui=documentEntryList]'

      behaviors: ->
        Role: [
          elements: [
            "[data-toolbar-action]"
          ]
          islock: ->
            return false if helpers.can { type: 'document', action: 'edit' }
            true
          mode: 'remove'
        ,
          elements: [
            "[data-toolbar-action=addEntry]"
          ]
          islock: =>
            return true if @options.isLockEntries
            false
          mode: ($el) =>
            islock = @options.isLockEntries
            $el.prop 'disabled', true
            .next()
            .text App.t "entry.document.#{islock.key}", context: 'error'
        ]

      collectionEvents:
        "reset remove": "reloadEntries"

      reloadEntries: ->
        _.each @options.conditions.toJSON(), (condition, index) =>
          entries = condition.entries
          _.each entries, (entry) =>
            model = @collection.findWhere
              ENTRY_TYPE : entry.ENTRY_TYPE
              ENTRY_ID   : entry.ENTRY_ID

            if not model
              condition = @options.conditions.getItem(index)

              if entries.length is 1
                @options.conditions.remove condition
                return

              condition.get('entries').remove entry

      childView: App.Views.Protected.DocumentEntryItem

      emptyView: App.Views.Protected.DocumentNoEntry

      events:
        'click [data-toolbar-action=addEntry]': ->
          data = @collection.getDataEntry()

          App.modal2.show new App.Views.Controls.DialogSelect
            action   : "add"
            type     : "document"
            checkbox : false
            data     : data
            title    : App.t "entry.document.entry_select", context: 'title'
            items    : @options.entries
            callback : (data) =>
              data = data[0]
              data = @collection.setDataEntry data
              @collection.reset data
              App.modal2.empty()
