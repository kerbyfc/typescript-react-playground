"use strict"

require "views/policy/action.coffee"
style = require "common/style.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Rule extends Marionette.CompositeView

      getTemplate: ->
        type = if @model.isSystem() then 'system' else @type
        "policy/rule/#{type}".toLowerCase()

      templateHelpers: ->
        type: @type

        channel: ->
          channel  = []
          events   = App.request "bookworm", "event"
          _.each @DATA.OBJECT_TYPE_CODE, (item) ->
            ev = events.get item
            if ev
              channel.push
                class : style.className.channel[ ev.get('mnemo') ]
                mnemo : ev.get('mnemo')
                name  : ev.get 'name'
          _.sortBy channel, 'name'

      ui:
        actionList : "[data-ui=actionList]"
        removeRule : "[data-action=removeRule]"

      childViewContainer: "@ui.actionList"

      childView: App.Views.Policy.Action

      emptyView: Marionette.ItemView.extend
        template  : 'policy/empty_action'
        tagName   : 'li'
        className : 'policyRuleAction'

      className: ->
        str = ""
        str = "#{style.className.default} " if @model.isSystem()
        str += "policyRuleItem"

      events:
        "click @ui.removeRule": (e) ->
          e?.preventDefault()
          Module.trigger "policy:item:delete", @, "Rule"

        "click": (e) ->
          e?.preventDefault()
          e?.stopPropagation()

          Module.trigger "policy:item:select", @, "Rule"

      selected: false

      modelEvents: ->
        "change": ->
          @collection = @model.getActions()
          @collection.on "remove add", @collectionEvents["remove add"]
          @render()
          @triggerMethod "show"

      collectionEvents: "remove add": -> "render"

      initialize: (opt) ->
        @type = @model.get "TYPE"
        @collection = @model.getActions()
        Module.trigger "policy:view:init", @

      onRender: ->
        @listenTo Module, "policy:item:clear:select", =>
          @selected = false
          @$el.removeClass "selected"

        self = @
        @$el.find '[data-dialog]'
        .on 'click', (e) =>
          $el = $ e.target
          if dialog = $el.data "dialog"
            view = App.Layouts.Application.sidebar.currentView

            if view.model isnt @model
              Module.trigger "policy:item:select", @, "Rule"

            # App.Layouts.Application.sidebar.currentView.dialog e, dialog
          e.stopPropagation()
          e.preventDefault()



