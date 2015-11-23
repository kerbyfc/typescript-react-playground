"use strict"

require "views/policy/sidebar/objects.coffee"
style = require "common/style.coffee"
entry = require "common/entry.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.Policy extends Marionette.LayoutView

      template: 'policy/sidebar/policy'

      templateHelpers: ->
        rules: @model.getRuleTypes()

      className: "sidebar__content"

      behaviors: ->
        Form:
          listen: @options.model
          syphon: true

      ui:
        dialog  : "[data-action=changeEntry]"
        rule    : "[data-action=addRule]"
        objects : "[data-region=objects]"

      regions:
        objects: "@ui.objects"

      events:
        "click :submit"    : "save"
        "click @ui.dialog" : "changeEntry"
        "click :reset"     : "reset"
        "click @ui.rule"   : "addRule"

      changeEntry: (e) ->
        data = @data.DATA.ITEMS
        data = _.map data, (item) ->
          item unless entry.isDeleted item
        data = _.compact data

        type = @model.get 'TYPE'

        App.modal.show new App.Views.Controls.DialogSelect
          action                 : "add"
          type                   : "policy"
          title                  : App.t "entry.policy.add_objects", context: type.toLowerCase()
          checkbox               : false
          preventSubmitDisabling : if type is 'OBJECT' then true else false
          data                   : data
          items                  : @model.getObjectTypes()

          callback: (data) =>
            App.entry.add _.pluck(data[0], 'content')
            App.modal.empty()

            data = _.map data[0], (item) ->
              delete item.content
              item

            @data.DATA.ITEMS = data
            @objects.currentView.render()
            @trigger 'change'

      addRule: (e) ->
        e.preventDefault()
        type  = $ e.currentTarget
        .data 'rule'

        Module.trigger "policy:sidebar:add:rule", @model, type

      save: (e) ->
        e.preventDefault()
        @model.save @serialize()

      reset: (e) ->
        e.preventDefault()
        Module.trigger "policy:item:select", @, "Content"

      onShow: ->
        @objects.show new App.Views.Policy.Sidebar.Objects
          model  : @model
          data   : @data
          parent : @

      serialize: ->
        data = super
        # TODO: реализовать на уровне модели
        data.DATA = _.cloneDeep @data.DATA
        _.extend data,
          START_DATE : data.START_DATE or null
          END_DATE   : data.END_DATE or null
