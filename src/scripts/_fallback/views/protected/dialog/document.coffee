"use strict"

App.module "Protected",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.DocumentCreate extends App.Views.Controls.DialogSelect
    class App.Views.Protected.DocumentEdit extends App.Views.Controls.DialogEdit

      template: "protected/dialog/document"

      regions:
        condition : "[data-region=condition]"
        entry     : "[data-region=entry]"

      ui:
        tab: "[data-tab]"

      modelEvents:
        "invalid": "openTab"

      events:
        "click @ui.tab": (e) ->
          $e   = $ e.currentTarget
          type = $e.data 'tab'

          if type is 'Entry'
            o =
              collection    : @data.entries_pool
              conditions    : @data.conditions
              entries       : @model.collection.entries
              isLockEntries : @model.collection.isLockEntries()
          else
            o =
              collection   : @data.conditions
              entries_pool : @data.entries_pool

          @[type.toLowerCase()].show new App.Views.Protected["Document#{type}"] o

      behaviors: -> _.merge super, Form: select: []

      exclude: [
        'FINGERPRINT_CONDITION_ID'
      ]

      serialize: ->
        data = super
        attr = @model.model2sectionAttribute
        o = _.find(@data[attr], CATALOG_ID: @model.collection.section.id)

        o.ENABLED = data.ENABLED
        delete data.ENABLED
        data[attr] = @data[attr]

        conditions = @data.conditions.toJSON()
        conditions = _.filter conditions, (item) ->
          return true if item.entries.length

        _.extend data,
          conditions   : conditions
          entries_pool : @data.entries_pool.toJSON()
        data

      templateHelpers: ->
        action   : @options.action
        isActive : @data.ENABLED

      openTab: ->
        tab = 0
        if @data.entries_pool.length
          conditions = @data.conditions
          if not conditions.length or
          not conditions.getItem(0).get('entries').length
            tab = 1

        @ui.tab.eq tab
        .trigger 'click'

      onShow: ->
        @openTab()
