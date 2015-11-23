"use strict"

require "views/controls/dialog.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TermCreate extends App.Views.Controls.DialogCreate

      template: "analysis/dialogs/term"

      ui:
        success : "[data-type=edit],[data-type=create]"

      serialize: ->
        data    = super
        section = @model.getSection()

        (_options = {})[section.idAttribute] = section.id
        attr        = @model.model2sectionAttribute
        dataSection = _.where @data[attr], _options

        data.WEIGHT = if +data.CHARACTERISTIC is 1 then 1 else +data.WEIGHT

        _data =
          CHARACTERISTIC : +data.CHARACTERISTIC
          ENABLED        : 1
          WEIGHT         : data.WEIGHT

        unless dataSection.length
          data[attr] = [ _data ]
          return data

        _.extend dataSection[0], _data

        data[attr] = @data[attr]
        data

      onShow: ->
        @on "form:change", =>
          @ui.success.show()

    class App.Views.Analysis.TermEdit extends App.Views.Analysis.TermCreate
