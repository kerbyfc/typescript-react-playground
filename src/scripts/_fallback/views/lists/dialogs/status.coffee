"use strict"

module.exports = class StatusDialog extends Marionette.ItemView

  template: "lists/dialogs/status"

  events:
    "click @ui.save": "save"

  ui:
    color : '[name="COLOR"]'
    save  : "[data-action='save']"

  templateHelpers: ->
    blocked: @blocked
    title: @title

  initialize: (options) ->
    @callback = options.callback
    @title = options.title
    @blocked = options.blocked

  save: (e) ->
    e.preventDefault()

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
      Backbone.Syphon.deserialize @, @model.toJSON(),
        exclude: ['CHANGE_DATE', 'CREATE_DATE']

    @ui.color.simplecolorpicker
      picker: true
