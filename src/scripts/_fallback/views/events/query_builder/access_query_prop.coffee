"use strict"

module.exports = class Access extends Marionette.ItemView

  template: 'events/query_builder/query_access'

  behaviors: ->
    Form:
      syphon : @options.model.toJSON()

  onShow: ->
    @listenTo @, "form:change", _.debounce =>
      data = @getData()

      @model.set data
    , 333
