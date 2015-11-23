"use strict"

require "views/dashboards/renderers/threats.coffee"
require "views/dashboards/renderers/users.coffee"
require "views/dashboards/renderers/policy_stats.coffee"
require "views/dashboards/renderers/category_stats.coffee"
require "views/dashboards/renderers/protected_document_stats.coffee"
require "views/dashboards/renderers/protected_catalog_stats.coffee"
require "views/dashboards/renderers/threats_stats.coffee"
require "views/dashboards/renderers/selection_stats.coffee"
require "views/dashboards/renderers/status_stats.coffee"

App.module "Dashboards",
  startWithParent: false
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards.WidgetRenderers ?= {}

    # Юзается паттерн [Фасад](http://goo.gl/V8EyJ)
    # Смотреть секцию "CoffeeScript"
    class App.Views.Dashboards.WidgetRenderers.Base

      constructor: (App) ->
        renderClasses = _.reject App.Views.Dashboards.WidgetRenderers, (classItem) ->
          classItem is @
        , @constructor

        rendersKeys = for own key, value of App.Views.Dashboards.WidgetRenderers
          if key isnt "Base"   then key.toLowerCase()   else continue

        @renders = _.object rendersKeys, _.map renderClasses, (classItem) ->
          new classItem()

      beforeReRenderWidget: (stat, view) ->
        if @renders[stat].beforeReRenderWidget
          @renders[stat].beforeReRenderWidget(view)

      widgetFlip: (stat, view) ->
        if @renders[stat].widgetFlip
          @renders[stat].widgetFlip(view)

      widgetFlop: (stat, view) ->
        if @renders[stat].widgetFlop
          @renders[stat].widgetFlop(view)

      closeWidget: (stat, view) ->
        @renders[stat].closeWidget(view)

      renderWidget: (stat, view) ->
        @renders[stat].renderWidget(view)

      renderWidgetSettings: (stat, view) ->
        @renders[stat].renderWidgetSettings(view)

      validateVidgetSettings: (stat, view) ->
        if @renders[stat].validateVidgetSettings?
          @renders[stat].validateVidgetSettings(view)
        else
          {}
