"use strict"

require "views/controls/dialog.coffee"
require "views/controls/grid.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TableConditionColumn extends App.Views.Controls.Grid

    class App.Views.Analysis.TableConditionCreate extends App.Views.Controls.DialogEdit

      template: "analysis/dialogs/table_condition"

      regions: columns: "[data-region=columns]"

      ui:
        VALUE    : '[name=VALUE]'
        MIN_ROWS : '[name=MIN_ROWS]'

      serialize: ->
        data = super
        data.MIN_ROWS = +data.MIN_ROWS
        delete data.search
        data[@model.idAttribute] = @model.id
        data

      onShow: ->
        section = @model.collection.section
        c = section.get 'CONDITION_COLUMNS'
        columns = if c then JSON.parse(c) else []

        model = @model
        # TODO: временное решение, в дальнейшем необходимо реализовать на уровне компонента form
        @ui.MIN_ROWS
        .on 'keypress', (e) ->
          if e.currentTarget.value.length >= 2 or e.charCode < 48 or e.charCode > 57
            e.preventDefault()
        .on 'change', (e) ->
          if @value and @value < 33 and @value > 0
            model.set 'MIN_ROWS', @value
          else
            @value = model.get 'MIN_ROWS'

        cols = for col, ind in columns
          ind    : ind + 1
          column : col

        return unless cols.length

        @columnTable = new App.Views.Analysis.TableConditionColumn
          collection : new App.Models.Analysis.TableConditionColumn cols
          static     : true

        @columns.show @columnTable

    class App.Views.Analysis.TableConditionEdit extends App.Views.Analysis.TableConditionCreate
