"use strict"

require "models/configuration/configuration.coffee"
require "models/configuration/configuration_log.coffee"

require "views/configuration/configuration.coffee"
require "views/configuration/dialogs/configuration.coffee"

App.module "Application.ConfigurationWatcher",
  startWithParent: true
  define: (Configuration, App, Backbone, Marionette, $) ->

    class ConfigurationController extends Marionette.Controller

      initialize: ->
        @configuration = new App.Models.Configuration.Configuration

      start: ->
        @configuration.startListener()

        # Получаем изначальное состояние конфигурации
        @configuration.fetch
          reset: true
          async: false

      stop: ->
        @configuration.stopListener()

        @hide()

      show: ->
        configurationPanel = new App.Views.Configuration.ConfigurationPanel(model: @configuration)

        @listenTo configurationPanel, 'commit', =>
          App.modal.show new App.Views.Configuration.ConfigurationLogDialog
            model: @configuration
            action: 'commit'
            collection: new App.Models.Configuration.ConfigurationLog
            callback: (data, view) =>
              @configuration.publishPolicy()
              .done =>
                @configuration.save
                  STATUS: "1"
                  NOTE: data.NOTE,
                    silent: true
                    success: ->
                      App.Configuration.trigger "configuration:commit"
                      App.modal.empty()
              .fail (jqXHR, textStatus) ->
                #console.log 'Не удалось собрать политки'

        @listenTo configurationPanel, 'rollback', =>
          App.modal.show new App.Views.Configuration.ConfigurationLogDialog
            action: 'rollback'
            model: @configuration
            collection: new App.Models.Configuration.ConfigurationLog
            callback: (data, view) =>
              @configuration.save
                NOTE: data.NOTE
                STATUS: "0",
                  silent: true
                  success: ->
                    App.Configuration.trigger "configuration:rollback"

              App.modal.empty()

        @listenTo configurationPanel, 'save', =>
          App.modal.show new App.Views.Configuration.ConfigurationLogDialog
            model: @configuration
            action: 'save'
            collection: new App.Models.Configuration.ConfigurationLog
            callback: (data, view) =>
              @configuration.save
                NOTE: data.NOTE
                STATUS: "2",
                  silent: true
                  success: ->
                    App.Configuration.trigger "configuration:save"

              App.modal.empty()

        @listenTo @configuration, 'change:STATUS', ->
          App.Configuration.trigger "configuration:change:status"

        App.Layouts.Application.configuration_panel.show configurationPanel

      hide: ->
        App.Layouts.Application.configuration_panel.empty()

      isLocked: ->
        return @configuration.isLocked()

      isEdited: ->
        return @configuration.isEdited()

      fetch: ->
        @configuration.fetch()

    # Initializers And Finalizers
    # ---------------------------
    Configuration.addInitializer ->
      App.Configuration = new ConfigurationController()
      App.Configuration.start()

    Configuration.addFinalizer ->
      App.Configuration.stop()
      delete App.Configuration
