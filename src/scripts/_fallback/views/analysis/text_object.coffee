"use strict"

require "views/controls/grid.coffee"
require "views/controls/dialog.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TextObject extends App.Views.Controls.ContentGrid

      addSystem: ->
        section = @collection.section

        system = @collection.where IS_SYSTEM: 1
        system = _.map system, (item) ->
          ID    : item.id
          NAME  : item.getName()
          TYPE  : "system_text_object"
          content : item

        App.modal.show new App.Views.Controls.DialogSelect
          action : "add"
          type   : "system_text_object"
          data   : system
          items  : [ "system_text_object" ]
          callback: (data) =>
            App.modal.empty()

            _.each _.pluck(data[0], 'content'), (data) =>
              proto = @collection.model::
              e2c = data[proto.model2sectionAttribute] ?= []
              (o = {})[section.idAttribute] = section.id
              o[proto.idAttribute] = data[proto.idAttribute]
              return if _.find e2c, o
              e2c.push o

              model = new @collection.model data,
                collection: @collection
              model.save null,
                success: => @collection.fetch()
