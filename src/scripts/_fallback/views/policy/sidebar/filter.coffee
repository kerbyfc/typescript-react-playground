"use strict"

entry = require "common/entry.coffee"
select2 = require "common/select2.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.Filter extends Marionette.ItemView

      template: 'policy/sidebar/filter'

      className: "sidebar__content"

      events:
        'click @ui.back'  : 'back'
        'click @ui.save'  : 'save'
        'change textarea' : ->
          if @ui.name.val() or @ui.object.val()
            @ui.reset.show()
          else
            @ui.reset.hide()

        "click @ui.reset": ->
          Module.trigger "policy:filter:reset", @

      ui:
        name   : "[name=POLICY_NAME]"
        object : "[name=OBJECT]"
        reset  : "[data-action=reset]"
        back   : "[data-action=back]"
        save   : "[data-action=save]"

      initialize: (o) ->
        @data = o.data

      back: ->
        App.Layouts.Application.sidebar.show new App.Views.Policy.Empty

      save: ->
        name = @ui.name.val()
        object = @ui.object.val()

        if not name and not object
          return Module.trigger "policy:filter:reset", @

        Module.filter =
          name   : select2.getVal name
          object : select2.getVal object

        Module.trigger "policy:filter:apply", @

      onDestroy: ->
        @ui.name
        .add @ui.object
        .select2 'destroy'

      onShow: ->
        self = @

        @ui.name.val select2.setVal @data.name if @data and @data.name?.length
        @ui.object.val select2.setVal @data.object if @data and @data.object?.length

        select2.set @ui.name,
          local  : null
          server : null
          minimumInputLength   : 0
          isAlwaysVisibleLabel : true
          query: (query) ->
            data = results: []

            objects = entry._hash
            _.each _.sortBy(objects.policy, 'DISPLAY_NAME'), (item) ->
              return if entry.isDeleted item

              _data = entry.getData item

              return unless _data
              return if _data.TYPE isnt "policy"
              if policy = Module.controller.collection.get(_data.ID)
                if query.term.length is 0 or
                policy.getName().toUpperCase().indexOf(query.term.toUpperCase()) >= 0
                  type = policy.get('TYPE').toLowerCase()
                  data.results.push _.extend(_data, TYPE: "policy_#{type}")

            query.callback data

        select2.set @ui.object,
          local  : null
          server : null
          minimumInputLength : 0
          query: (query) ->
            items = Module.controller.collection.pluck 'DATA'
            items = _.pluck items, 'ITEMS'
            items = _.union.apply null, items
            items = _.sortBy items, 'TYPE'

            items = _.map items, (item) ->
              item = entry.get item.TYPE, item.ID
              return if entry.isDeleted item
              _data = entry.getData item
              _data.id = "#{_data.TYPE}#{_data.ID}"
              if query.term.length is 0 or
              _data.NAME.toUpperCase().indexOf(query.term.toUpperCase()) >= 0
                return _data

            items = _.uniq items, 'id'
            items = results: _.compact items

            query.callback items

        @$el.find "textarea"
        .trigger "change"
