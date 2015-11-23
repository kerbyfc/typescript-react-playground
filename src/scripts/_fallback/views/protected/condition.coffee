"use strict"

helpers = require "common/helpers.coffee"
require "views/protected/entry.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.DocumentNoCondition extends Marionette.ItemView

      template: "protected/no_condition"

    class App.Views.Protected.DocumentConditionItem extends Marionette.CompositeView

      template: "protected/condition_item"

      className: "queryBuilder__block _linkDisabled"

      attributes: ->
        "data-content": @model.t "global.or"

      ui: select2: "[data-toolbar-action=addEntry]"

      onRender: ->
        @ui.select2
        .select2 minimumResultsForSearch: 10

      templateHelpers: ->
        pool  = []
        types = []

        @options.entries.each (entry) =>
          return if @collection.get entry.id
          entryType = entry.get('content').TYPE
          data = entry.toJSON true

          # TODO: выпилить этот жесткий хардкод, когда будет единое видение,
          # что такое сущность и какой у сущности должен быть тип
          # вариант графический объект это fingerprint, и одновременно homography
          # или classifier, не вариант. При этом одни сущности забираются api/fingerprint, а
          # другие api/EtGraph. Эта же проблема наблюдается и для каталогов ЭНТ.
          type = "stamp" if entryType is "stamp"
          type = "graphic" if entryType is "homography" or entryType is "classifier"
          data.type = type = type or data.ENTRY_TYPE

          types.push type
          pool.push data

        can       : helpers.can { type: 'document', action: 'edit' }
        entryType : _.unique types
        entryPool : pool

      childViewOptions: ->
        template : "protected/condition_entry"

      initialize: ->
        @collection = @model.get 'entries'

        @listenTo @collection, 'remove', => _.defer => @render()

      childViewContainer: '[data-ui=documentConditionList]'

      childView: App.Views.Protected.DocumentEntryItem

      events:
        'click [data-toolbar-action=deleteEntry]': ->
          @model.collection.remove @model

        'change [data-toolbar-action=addEntry]' : (e) ->
          val   = e.val.split '::'
          type  = if val[0] is 'graphic' or val[0] is 'stamp' then 'fingerprint' else val[0]

          entry = @options.entries
          .where
            ENTRY_TYPE : type
            ENTRY_ID   : val[1]

          return unless entry.length
          condition = @model.collection.section.getDefaultCondition entry[0].toJSON(), true
          @collection.add condition
          @render()

    class App.Views.Protected.DocumentCondition extends Marionette.CompositeView

      template: "protected/condition"

      templateHelpers: ->
        entries_pool: @options.entries_pool

      childViewContainer: '[data-ui=conditionList]'

      childView: App.Views.Protected.DocumentConditionItem

      emptyView: App.Views.Protected.DocumentNoCondition

      ui:
        buttons : "[data-toolbar-action]"
        add     : "[data-toolbar-action=add]"

      behaviors: ->
        Role: [
            elements: [
              @ui.buttons
            ]
            islock: ->
              return false if helpers.can { type: 'document', action: 'edit' }
              true
            mode: "remove"
          ]

      childViewOptions: ->
        entries: @options.entries_pool

      attachHtml: (cv, iv) ->
        $container = @getChildViewContainer @
        $container.prepend iv.el

      events:
        'click @ui.add': ->
          model = new @collection.model
          @collection.add model
