"use strict"

config = require "settings/config.json"
require "common/entry.coffee"
require "layouts/application.coffee"
require "models/settings/licenses.coffee"

App.module "Application",
  startWithParent: false
  define: (Application, App, Backbone, Marionette, $) ->

    ApplicationController = ->

    ApplicationController:: =
      start: ->
        # Основной обработчик ссылок
        # Если ссылка не содержит параметра data-bypass
        # она будет обработанна через роутер
        selector = "a[data-bypass]"
        $(document).on "click", selector, (evt) ->
          href =
            prop: $(@).prop "href"
            attr: $(@).attr "href"

          root = location.protocol + "//" + location.host + config.root

          evt?.preventDefault()

          if href.prop and
          href.prop.slice(0, root.length) is root and
          App.Routes.Application.currentModuleName?.toLowerCase() isnt href.attr
            $(selector).removeClass "selected"
            Backbone.history.navigate href.attr, true

        App.startAppModule = (moduleName, options) ->
          # Форсировать закрытие сайдбара как опционального региона
          # Всё равно, где он понадобится, заюзается на уровне конкретного модуля
          App.Layouts.Application.sidebar.empty()

          App.Layouts.Application.header.currentView.$el.find('li a.selected').removeClass "selected"

          $(selector).closest("[href="+moduleName.toLowerCase()+"]").addClass "selected"

          currentModule = App.module(moduleName)
          if App.currentModule
            App.currentModule.stop()

          currentModule.start(options)

          App.currentModule = currentModule

        App.vent.on "start:module", App.startAppModule, App
        App.main.show App.Layouts.Application

      stop: ->
        App.currentModule.stop() if App.currentModule
        App.currentModule = null

        $(document).off "click", "a[data-bypass]"
        App.vent.off "start:module"
        App.main.empty()


    # Initializers And Finalizers
    # ---------------------------
    Application.addInitializer ->
      App.Controllers.Application = new ApplicationController
      App.Controllers.Application.start()

    Application.addFinalizer ->
      App.Controllers.Application.stop()
      delete App.Controllers.Application
