"use strict"

require "views/controls/grid.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.Stamp extends App.Views.Controls.ContentGrid
