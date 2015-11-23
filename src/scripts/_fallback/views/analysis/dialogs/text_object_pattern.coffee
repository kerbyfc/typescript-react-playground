"use strict"

App.module "Analysis.Dialogs",
  startWithParent: true

  define: (Module, App) ->

    App.Views.Analysis ?= {}

    class App.Views.Analysis.TextObjectPatternCreate extends App.Views.Controls.DialogCreate

      template: "analysis/dialogs/text_object_pattern"

      events: "click @ui.verify" : "validateRegexp"

      serialize: ->
        data = super
        section = @model.collection.section
        data.TEXT_OBJECT_ID = section?.id
        data

      ui:
        verification : "[data-ui=verification]"
        validation   : "[data-ui=validation]"
        textLabel    : "[data-ui=textLabel]"
        textInput    : "[data-ui=textInput]"
        checkbox     : "[name=IS_REGEXP]"
        verify       : "[data-ui=verify]"
        regexp       : "[data-ui=regexp]"

      validateRegexp: (e) ->
        e.preventDefault()

        data = @serialize()

        if +data.IS_REGEXP and data.TEXT
          expr = new RegExp data.TEXT, 'ig'
          value = @ui.validation.val()

          @ui.verification.html value
          context = @ui.verification[0].childNodes[0]
          verification = @ui.verification.text()

          dt = []
          verification = verification.replace /\n/g, ' '
          result = expr.exec verification
          while ((result isnt null) and (result[0] isnt ''))
            dt.push result
            result = expr.exec verification

          if dt.length
            for i in [(dt.length-1)..0]
              range = document.createRange()

              range.setStart context, dt[i].index
              range.setEnd context, dt[i].index + dt[i][0].length
              range.surroundContents $('<span style="background-color: #AFD68B;"/>')[0]
              range.detach()

          html = @ui.verification.html()

          @ui.verification.html html.replace(/\n/g, '<br>')

          @ui.verify.focus()

      showInput: (value) ->
        if +value
          type = 'regexp'
          @ui.regexp.show()
        else
          type = 'string'
          @ui.regexp.hide()

        @ui.textLabel
        .text App.t "entry.text_object_pattern.#{type}"
        @ui.textInput
        .attr 'placeholder', App.t("entry.text_object_pattern.#{type}", context: 'placeholder')

      onShow: ->
        self = @
        @ui.checkbox.on 'change', -> self.showInput @value
        @showInput @data.IS_REGEXP

    class App.Views.Analysis.TextObjectPatternEdit extends App.Views.Analysis.TextObjectPatternCreate
