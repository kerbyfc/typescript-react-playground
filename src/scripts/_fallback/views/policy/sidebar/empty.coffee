"use strict"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Empty extends Marionette.ItemView

      template: "policy/sidebar/empty"

      className: "sidebar__content"

    class App.Views.Policy.ContentEmpty extends Marionette.ItemView

      template: "policy/empty"

      className: "content policy"
