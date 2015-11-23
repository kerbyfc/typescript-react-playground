"use strict"

require "views/controls/grid.coffee"
require "views/controls/dialog.coffee"
require "views/analysis/dialogs/fingerprint.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TableEdit extends App.Views.Analysis.UpdateEdit

      template: "analysis/dialogs/table_edit"

      type: "table_condition"

      regions: regionTable: "[data-region=table]"

      behaviors: ->
        behaviors = super

        Dialog  : behaviors.Dialog
        Form    : behaviors.Form

      serialize: -> _.extend super, conditions: @data.conditions.toJSON()

      onShow: ->
        return if @model.isNew()

        @collection = @data.conditions

        @table = new App.Views.Controls.ContentGrid
          collection : @collection
          static     : true
          popup      : true

        @regionTable.show @table
