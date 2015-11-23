"use strict"

require "views/policy/rule.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Rules extends Marionette.CompositeView

      template: 'policy/rules'

      className: "policyRule"

      childViewContainer: "@ui.ruleList"

      childView: App.Views.Policy.Rule

      collectionEvents:
        "change add create remove": ->
          Module.trigger "policy:update:rules:length", @

      events: "click @ui.addRule": "add"

      ui:
        ruleList : "[data-ui=ruleList]"
        addRule  : "[data-action=addRule]"

      onRender: -> Module.trigger "policy:view:init", @

      attachHtml: (cv, iv) ->
        if iv.model.get('TYPE') is @options.type
          @ui.ruleList.prepend iv.el

      add: (e) ->
        e?.preventDefault()
        e?.stopPropagation()

        rule = new App.Models.Policy.RuleItem
          TYPE    : @options.type
          POLICY_ID : @model.getPolicy().id

        @collection.once "add", ->
          Module.trigger "rule:add:after", rule

        @collection.add rule
