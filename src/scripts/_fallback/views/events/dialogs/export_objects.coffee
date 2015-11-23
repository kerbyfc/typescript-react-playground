"use strict"

module.exports = class ExportObjects extends Marionette.ItemView

  template: "events/dialogs/export_objects"

  ui:
    form                                        : "form"

  events:
    'click [data-action="save"]'                : 'save'

  templateHelpers: ->
    title: @options.title
    selected: @options.selected

  save: (e) ->
    e?.preventDefault()

    data = Backbone.Syphon.serialize @

    @options.callback(data) if @options.callback
