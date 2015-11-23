"use strict"

require "views/controls/tree.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Protected ?= {}

    class App.Views.Protected.Catalog extends App.Views.Controls.SidebarTree
