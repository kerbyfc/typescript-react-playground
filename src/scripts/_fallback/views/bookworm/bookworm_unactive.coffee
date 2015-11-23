"use strict"

App.module "Bookworm",
  startWithParent: true

  define: (Module, App) ->
    App.Bookworm ?= {}

    class App.Bookworm.BookwormUnactive extends Marionette.ItemView

      template: "bookworm/bookworm_unactive"
