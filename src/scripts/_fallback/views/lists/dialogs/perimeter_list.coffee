"use strict"

module.exports = class PerimeterListDialog extends Marionette.ItemView

  template: "lists/dialogs/perimeter_list"

  events:
    "click [data-action='save']" : "save"

  templateHelpers: ->
    blocked: @options.blocked
    title: @options.title

  save: (e) ->
    e?.preventDefault()

    # Собираем данные с контролов
    data = Backbone.Syphon.serialize @,
      exclude: ['CHANGE_DATE', 'CREATE_DATE']

    @options.callback(data)

  onDestroy: ->
    App.Common.ValidationModel::.unbind(@)

  onShow: ->
    App.Common.ValidationModel::.bind(@)

    data = @model.toJSON()

    Backbone.Syphon.deserialize @, data,
      exclude: ['CHANGE_DATE', 'CREATE_DATE']
