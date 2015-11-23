"use strict"
entry = require "common/entry.coffee"
style = require "common/style.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.Objects extends Marionette.ItemView

      template: "policy/sidebar/objects"

      templateHelpers: ->
        objects = @options.data.DATA.ITEMS

        types   : _.unique _.pluck(objects, 'TYPE')
        objects : objects

      ui:
        removeEntry : "[data-action=removeEntry]"
        message     : "[data-ui=message]"

      onRender: ->
        @changeMessage()

      changeMessage: ->
        objects = @options.data.DATA.ITEMS

        isDeleted = _.filter objects, (item) ->
          entry.isDeleted item

        if isDeleted.length
          message = 'broken'
          method = 'add'
        else
          message = 'any_object_sidebar'
          method = 'remove'

        @ui.message["#{method}Class"] style.className.broken
        .text App.t "entry.policy.#{message}"

      events:
        "click @ui.removeEntry": (e) ->
          el = e.currentTarget
          data    = el.dataset
          objects = @options.data.DATA.ITEMS

          @options.data.DATA.ITEMS = _.reject objects,
            TYPE : data.type
            ID   : data.id

          $(el).parent().remove()
          @changeMessage()
          @options.parent.trigger "change"
