"use strict"

module.exports = class ResourceListDialog extends Marionette.ItemView

  template: "lists/dialogs/resource_list"

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

    data.DISPLAY_NAME = _.unescape data.DISPLAY_NAME
    data.NOTE = _.unescape data.NOTE

    Backbone.Syphon.deserialize @, data,
      exclude: ['CHANGE_DATE', 'CREATE_DATE']
