"use strict"

require "behaviors/common/popover.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->
    App.Views.Policy ?= {}

    class App.Views.Policy.Objects extends Marionette.ItemView

      getTemplate: ->
        types = @model.getCurrentObjectTypes()
        objects = @model.getObjects()
        total = objects.length

        tpl = "0"
        tpl = "1" if types.length is 1 and total is 1
        tpl = "2" if types.length is 1 and total is 2
        tpl = "3" if types.length is 1 and total is 3
        tpl = "4" if types.length is 1 and total  > 3
        tpl = "5" if types.length is 2 and total is 2
        tpl = "6" if types.length >= 2 and total

        "policy/objects/#{tpl}"

      templateHelpers: ->
        types   : @model.getCurrentObjectTypes()
        objects : @model.getObjects()
        total   : @model.getObjects().length

      className: "policyObject"

      behaviors: ->
        Popover: [
          elements: [
            '[data-trigger=click]'
          ]
          content: =>
            Marionette.Renderer.render "controls/popover/list",
              types : @model.getCurrentObjectTypes()
              objects : @model.getObjects()
        ]
