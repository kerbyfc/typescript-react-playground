"use strict"

require "views/controls/grid.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.Document extends App.Views.Controls.ContentGrid
