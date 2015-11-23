"use strict"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Action extends Marionette.ItemView

      template: 'policy/action'

      modelEvents: "change": "render"

      tagName : "li"

      behaviors: ->
        Popover: [
          elements: [
            '[data-type]'
          ]
          content: =>
            data = @model.get('DATA')
            type = @model.get('TYPE').toLowerCase()

            Marionette.Renderer.render "policy/action/#{type}",
              type  : type
              data  : @model.get('DATA').VALUE
        ]


