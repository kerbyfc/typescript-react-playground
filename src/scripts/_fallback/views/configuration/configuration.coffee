"use strict"

require "bootstrap"
require "models/settings/user.coffee"

App.module "Configuration",
  startWithParent: false
  define: (Configuration, App, Backbone, Marionette, $) ->

    App.Views.Configuration ?= {}

    class App.Views.Configuration.ConfigurationPanel extends Marionette.ItemView

      template: "configuration/configuration_panel"

      className: 'systemMessage'

      triggers:
        "click #commit"   : "commit"
        "click #save"   : "save"
        "click #rollback" : "rollback"

      modelEvents:
        "change:STATUS" : 'render'

      templateHelpers: locale: App.t "settings.users", returnObjectTrees: true

      attachElContent: (html) ->
        # Ищем существующий контент
        currentContent = @$el.find('div')
        # Если не нашли просто добавляем содержимо вьюхи
        if currentContent.length is 0
          @$el.append html
        else
        # Если нашли то добавлем содержимое вьюхи и скрываем текущий контент
          @$el.append html
          currentContent.slideUp 1000, -> currentContent.remove()
        @
