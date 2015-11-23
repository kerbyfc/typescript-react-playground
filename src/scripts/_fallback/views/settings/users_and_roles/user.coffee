"use strict"

require "bootstrap"
helpers = require "common/helpers.coffee"
require "views/controls/form_view.coffee"

App.module "Settings",
  startWithParent: true
  define: (Settings, App, Backbone, Marionette, $) ->

    App.Views.Settings ?= {}

    class App.Views.Settings.UserDialog extends Marionette.ItemView

      template: "settings/users_and_roles/user"

      events:
        "click [data-action='save']": "save"

      templateHelpers: ->
        title: @options.title
        blocked: @options.blocked

      behaviors: ->
        data = {}

        data = @options.model.toJSON()
        data.LANGUAGE = App.Session.currentUser().get 'LANGUAGE'
        data.STATUS = 1 - data.STATUS

        Form:
          listen : @options.model
          syphon : data

      save: (e) ->
        e.preventDefault()

        return unless helpers.can({action: 'edit', type: 'user'})

        data = @getData()

        data.STATUS = 1 - data.STATUS

        @model.save data,
          wait: true
          success: (model) =>
            @destroy()

            @collection.add @model  unless @collection.get(model.id)

            @callback?()
