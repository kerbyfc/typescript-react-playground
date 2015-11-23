"use strict"

require "views/controls/grid.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.Graphic extends App.Views.Controls.ContentGrid

      updateHeader: ->
        @ui.header.text App.t 'select_dialog.graphic', context: 'many'

        App.trigger "resize", "header", @
