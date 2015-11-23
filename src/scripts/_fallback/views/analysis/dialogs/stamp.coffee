"use strict"

require "views/controls/dialog.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.StampEdit extends App.Views.Controls.DialogEdit

      template: "analysis/dialogs/stamp_edit"
