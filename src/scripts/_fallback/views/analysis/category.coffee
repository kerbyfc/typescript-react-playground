"use strict"

require "views/controls/tree.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.Category extends App.Views.Controls.SidebarTree
