"use strict"
require "views/controls/dialog.coffee"

App.module "Protected",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.CatalogCreate extends App.Views.Controls.DialogCreate

      template: "protected/dialog/catalog"

      templateHelpers: ->
        parent = @model.getParentModel()

        action   : @options.action
        title    : @options.title
        isActive : if parent then parent.get('ENABLED') else 1

    class App.Views.Protected.CatalogEdit extends App.Views.Protected.CatalogCreate
