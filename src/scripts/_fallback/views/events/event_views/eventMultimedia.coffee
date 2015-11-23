"use strict"

co        = require "co"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventMultimedia extends EventMain

  template: 'events/event_views/eventMultimedia'

  events:
    "click [data-region='eventParts'] > [data-type='attach']"         : 'showAttach'
    "click [data-region='eventParts'] [data-action='downloadAttach']" : 'downloadAttach'

  ui:
    text                        : '.text'

  templateHelpers: ->
    data: @data

  parse: ->
    @data = {}

    headers = @model.get 'headers'
    content = @model.get 'content'

    if not content and not headers
      throw new Error("Missing headers or content.")

    co =>
      [@data.properties, @data.attachments] = yield [
        @_getEventProperties(headers, content)
        @_getAttachments(content)
      ]

  onShow: ->
    super

    @showAttach() if @data.attachments
