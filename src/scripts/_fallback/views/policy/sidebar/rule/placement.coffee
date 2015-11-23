"use strict"

style = require "common/style.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.RulePlacement extends Marionette.ItemView

      template: 'policy/sidebar/rule/placement'

      templateHelpers: ->
        type    : @model.get 'TYPE'

        channel : ->
          services = App.request("bookworm", "service").toJSON()

          services = _.filter services, (item) ->
            return true if item.mnemo in [ "placement" ]
            false

          _.sortBy services, 'name'

      behaviors: ->
        Form:
          listen : @options.model
          submit : @options.save
          syphon : @options.model.toJSON()

      get: -> @getData()
