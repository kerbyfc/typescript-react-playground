"use strict"

module.exports = class SelectLayoutDialog extends Marionette.ItemView

  template: "dashboards/dialogs/select_layout"

  events:
    "click [data-action='save']" : "save"

  save: (e) ->
    e.preventDefault()

    @options.callback Backbone.Syphon.serialize @

  onShow: ->
    Backbone.Syphon.deserialize @, @model.toJSON()
