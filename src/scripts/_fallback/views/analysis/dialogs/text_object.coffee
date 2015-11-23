"use strict"

require "views/controls/dialog.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TextObjectCreate extends App.Views.Controls.DialogCreate

      template: "analysis/dialogs/text_object"

      ui:
        success : "[data-type=edit],[data-type=create]"
        add     : "[data-type=add]"

      modelEvents:
        copy: (model) ->
          @ui.add.show()

      templateHelpers: ->
        _.extend super, isNew: @model.isNew()

      serialize: ->
        data = super
        section = @model.collection.section

        (o = {})[section.idAttribute] = section.id
        o[@model.idAttribute] = @model.id
        data[@model.model2sectionAttribute] = [o]

        data

      regions: regionTable: "[data-region=table]"

      exclude: ['search', 'TYPE']

      onShow: ->
        return if @model.isNew()

        @collection = @data.text_object_patterns

        @table = new App.Views.Analysis.TextObjectPattern
          collection : @collection
          static     : true
          popup      : true

        @regionTable.show @table

        @collection.fetch()

    class App.Views.Analysis.TextObjectEdit extends App.Views.Analysis.TextObjectCreate
