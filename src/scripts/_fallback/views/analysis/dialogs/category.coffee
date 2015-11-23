"use strict"

require "views/controls/dialog.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.GroupCreate extends App.Views.Controls.DialogCreate

      template: "analysis/dialogs/group"

    class App.Views.Analysis.CategoryCreate extends App.Views.Analysis.GroupCreate

      template: "analysis/dialogs/group_term"

    class App.Views.Analysis.GroupFingerprintCreate extends App.Views.Analysis.GroupCreate

      ui:
        slider           : "[name=FP_TEXT_VALUE_THRESHOLD]"
        binary_threshold : "[name=FP_BIN_VALUE_THRESHOLD]"

      template: "analysis/dialogs/group_fingerprint"

      serialize: ->
        _.extend super,
          FP_TEXT_VALUE_THRESHOLD : @ui.slider.slider "value"
          FP_BIN_VALUE_THRESHOLD  : @ui.binary_threshold.slider "value"

      onShow: ->
        can = @model.can 'edit'
        $ @ui.slider
        .slider
          min      : 0
          max      : 100
          disabled : not can
          create   : @createSliderValue
          slide    : @updateSliderValue
          value    : @data.FP_TEXT_VALUE_THRESHOLD

        $ @ui.binary_threshold
        .slider
          min      : 0
          max      : 100
          disabled : not can
          create   : @createSliderValue
          slide    : @updateSliderValue
          value    : @data.FP_BIN_VALUE_THRESHOLD

      createSliderValue: (e, ui) =>
        $el = $(".ui-slider-handle", $(e.target))
        if @model.islock 'edit'
          $el.on 'click', (e) -> e.preventDefault()
        $(
          """
            <div>
              <div class='ui-slider-handle--value'>
                #{@model.get($(e.target).attr('name'))}
              </div>
              <div class='ui-slider-handle--value-carret'></div>
            </div>
          """
        ).appendTo $el

      updateSliderValue: (e, ui) ->
        $ e.target
        .find ".ui-slider-handle--value"
        .text ui.value

    class App.Views.Analysis.GroupTextObjectCreate extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupFormCreate extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupStampCreate extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupTableCreate extends App.Views.Analysis.GroupCreate

    class App.Views.Analysis.CategoryEdit extends App.Views.Analysis.CategoryCreate
    class App.Views.Analysis.GroupFingerprintEdit extends App.Views.Analysis.GroupFingerprintCreate
    class App.Views.Analysis.GroupTextObjectEdit extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupFormEdit extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupStampEdit extends App.Views.Analysis.GroupCreate
    class App.Views.Analysis.GroupTableEdit extends App.Views.Analysis.GroupCreate

    class App.Views.Analysis.GroupDelete extends App.Views.Controls.DialogDelete

      template: "analysis/dialogs/group_delete"

      initialize: (o) -> @model = o.selected?[0]

    class App.Views.Analysis.CategoryDelete extends App.Views.Analysis.GroupDelete
    class App.Views.Analysis.GroupFingerprintDelete extends App.Views.Analysis.GroupDelete
    class App.Views.Analysis.GroupTextObjectDelete extends App.Views.Analysis.GroupDelete
    class App.Views.Analysis.GroupFormDelete extends App.Views.Analysis.GroupDelete
    class App.Views.Analysis.GroupStampDelete extends App.Views.Analysis.GroupDelete
    class App.Views.Analysis.GroupTableDelete extends App.Views.Analysis.GroupDelete
