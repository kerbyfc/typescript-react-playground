"use strict"

entry   = require "common/entry.coffee"
helpers = require "common/helpers.coffee"
style   = require "common/style.coffee"
require "views/policy/rules.coffee"
require "views/policy/objects.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Policy extends Marionette.LayoutView

      template: 'policy/policy'

      templateHelpers: ->
        rules: @model.getRuleTypes() or []

      className: "policyItem"

      regions:
        container : "[data-region=content]"
        object    : "[data-region=object]"

      selected: false

      modelEvents:
        "change": (model) ->
          state = model.get 'STATUS'
          @$el
          .removeClass style.className.inactive
          .removeClass style.className.broken

          @$el.addClass style.className.inactive if state is 0

          objects = model.getObjects()

          isDeleted = _.filter objects, (item) ->
            entry.isDeleted item

          if state is 2 or isDeleted.length
            @$el.addClass style.className.broken

        "change:DISPLAY_NAME": (model, value) ->
          @ui.header.text value

        "change:DATA": ->
          @object.show new App.Views.Policy.Objects model: @model

        "error": ->
          App.Notifier.showError
            title : App.t "select_dialog.policy", context: "many"
            text  : App.t "save",
              postProcess : "entry"
              entry       : "policy"
              context     : "error"

        "sync": (model) ->
          @ui.header.attr "data-entry-id", @model.id

      events:
        "click @ui.remove": (e) ->
          e?.preventDefault()
          Module.trigger "policy:item:delete", @, "Policy"

        "click": (e) ->
          e?.preventDefault()
          Module.trigger "policy:item:select", @, "Policy"

        "click @ui.menu": (e) ->
          $el = $(e.target).closest '[data-rule]'
          action = if $el.hasClass('selected') then 'hide' else 'open'
          @[action] $el.data "rule"

      ui:
        header : "[data-ui=header]"
        menu   : "[data-rule]"
        remove : "[data-action=remove]"

      initialize: (opt) ->
        @listenTo Module, "policy:update:rules:length", (view, type) =>

          model = view.model.getPolicy()
          type = type ? view.options.type

          return if model isnt @model
          el = @$el.find("[data-rule=#{type}] [data-rule-count]")

          system = model.getRules().where
            IS_SYSTEM : 1
            TYPE      : type

          if system.length and not system[0].getActions().length
            system = system.length
          else
            system = 0

          if l = model.getRules(type).length - system
            el.text(l).show()
          else
            el.hide()

        Module.trigger "policy:view:init", @

      onRender: ->
        _.each @model.getRuleTypes(), (item) =>
          Module.trigger "policy:update:rules:length", @, item

        @object.show new App.Views.Policy.Objects model: @model

        @listenTo Module, "policy:item:clear:select", =>
          @selected = false
          @$el.removeClass style.className.selected

        @model.trigger "change", @model

      open: (type) ->
        @ui.menu.removeClass style.className.selected
        $el = @$el.find "[data-rule=#{type}]"
        $el.addClass style.className.selected

        @container.show new App.Views.Policy.Rules
          model      : @model
          collection : @model.getRules()
          type       : type

      hide: (type) ->
        @ui.menu.removeClass style.className.selected
        @container.empty()
