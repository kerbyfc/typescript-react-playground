"use strict"

require "jquery.simplecolorpicker"

module.exports = class TagDialog extends Marionette.ItemView

  template: "lists/dialogs/tag"

  ui:
    color : '[name="COLOR"]'
    save  : "[data-action='save']"

  events:
    "click @ui.save": "save"

  initialize: (options) ->
    @callback = options.callback
    @title = options.title
    @blocked = options.blocked

  templateHelpers: ->
    blocked: @blocked
    title: @title

  save: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).prop('disabled') then return

    # Собираем данные с контролов
    data = Backbone.Syphon.serialize @,
      exclude: ['CHANGE_DATE', 'CREATE_DATE']

    @callback(data)

  onDestroy: ->
    App.Common.ValidationModel::.unbind(@)

    @ui.color.simplecolorpicker('destroy')

  onShow: ->
    App.Common.ValidationModel::.bind(@)

    if not @model.isNew()
      data = @model.toJSON()

      Backbone.Syphon.deserialize @, data,
        exclude: ['CHANGE_DATE', 'CREATE_DATE']

    @ui.color.simplecolorpicker
      picker: true

    # ToDO: Костыль для мигратора
    if not @model.isNew()
      if data.COLOR not in [
        '#4e954e',
        '#5484ed',
        '#a4bdfc',
        '#af5050',
        '#7ae7bf',
        '#cc7a29',
        '#fbd75b',
        '#ffb878',
        '#ff0000',
        '#dc2127',
        '#dbadff',
        '#be9b33'
      ]
        @$('.simplecolorpicker').css 'background-color', data.COLOR
