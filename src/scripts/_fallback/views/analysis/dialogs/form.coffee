"use strict"

require "views/controls/dialog.coffee"
require "views/analysis/dialogs/fingerprint.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.FormEdit extends App.Views.Analysis.UpdateEdit

      template: "analysis/dialogs/form_edit"
