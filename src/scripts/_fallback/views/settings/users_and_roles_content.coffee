"use strict"

helpers = require "common/helpers.coffee"
FancyTree = require "views/controls/fancytree/view.coffee"

App.module "Settings",
  startWithParent: false
  define: (Settings, App, Backbone, Marionette, $) ->

    App.Views.Settings ?= {}

    class App.Views.Settings.UsersAndRolesContent extends FancyTree

      className: "sidebar__content"

      template: "settings/access"

      options:
        icons: false
        checkbox: false

      scope: "settings"

      initialize: ->
        @sections = []

        for section in ['user', 'role', 'scope']
          if helpers.can(type: section)
            @sections.push
              key: "#{section}s"
              title: App.t "settings.#{section}s_tab"

      getSource: ->
        @sections

      onShow: ->
        super

        @setActiveNode @sections[0].key
