"use strict"

require "views/controls/grid.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.Term extends App.Views.Controls.ContentGrid
