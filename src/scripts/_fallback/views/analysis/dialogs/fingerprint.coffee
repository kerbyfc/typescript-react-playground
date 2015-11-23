"use strict"

require "views/controls/dialog.coffee"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.DialogUpdate extends App.Views.Controls.Dialog

      template: 'analysis/dialogs/update'

      ui: replace: "[name=replace]"

      get: -> +@ui.replace.filter(':checked').val()

    class App.Views.Analysis.UpdateEdit extends App.Views.Controls.DialogEdit

      modelEvents:
        update: ->
          model = @model
          @modal = if App.modal.currentView then App.modal2 else App.modal
          @modal.show new App.Views.Analysis.DialogUpdate
            model  : model
            selected : []
            action   : "update"
            type   : model.type
            callback: => @update.call @, arguments...

      update: (isAdd) ->
        url    = _.result @model, 'urlRoot'
        module = App.currentModule.moduleName.toLowerCase()
        action = "update"
        type   = @model.type

        App.notify.fileupload
          url : "#{url}/compile"
          add : (e, data) =>
            file = data.files[0]

            o =
              type      : type
              action    : action
              name      : file.name
              state     : "upload"
              sectionId : @model.collection.section.id
              module    : module

            model = App.notify.add o

            (o ={})[@model.idAttribute] = @model.id

            o.UPDATE_MODE = if isAdd then "ADD" else "OVERWRITE"

            App.notify.send
              files    : data.files
              cid      : model.cid
              formData : o
              options  : file
            .done (result) =>
              data  = result.data
              model = App.notify.get data.key
              model.set 'state', 'sent'

              @model.fetch
                success: =>
                  data = @model.deserialize()
                  @data = data
                  Backbone.Syphon.deserialize @, data

            .always ->
              App.modal.empty()
              App.modal2.empty()

    class App.Views.Analysis.FingerprintEdit extends App.Views.Analysis.UpdateEdit

      template: "analysis/dialogs/fingerprint_edit"

      ui:
        quotes         : '#quotes'
        TEXT_VALUE_THRESHOLD : "[name=TEXT_VALUE_THRESHOLD]"
        BIN_VALUE_THRESHOLD  : "[name=BIN_VALUE_THRESHOLD]"

      serialize: ->
        _.extend super,
          BIN_VALUE_THRESHOLD  : @ui.BIN_VALUE_THRESHOLD.slider "value"
          TEXT_VALUE_THRESHOLD : @ui.TEXT_VALUE_THRESHOLD.slider "value"

      onShow: ->
        can = @model.can 'edit'

        $ @ui.TEXT_VALUE_THRESHOLD
        .slider
          disabled : not can
          min      : 0
          max      : 100
          create   : @createSliderValue
          slide    : @updateSliderValue
          value    : @data.TEXT_VALUE_THRESHOLD

        $ @ui.BIN_VALUE_THRESHOLD
        .slider
          disabled : not can
          min      : 0
          max      : 100
          create   : @createSliderValue
          slide    : @updateSliderValue
          value    : @data.BIN_VALUE_THRESHOLD

        @ui.quotes.popover
          trigger   : 'hover'
          title     : App.t 'analysis.fingerprint.quantity_threshold'
          content   : App.t 'analysis.fingerprint.quantity_threshold_hint'
          container : '#quotes'

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
