"use strict"

co        = require "co"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventPlacement extends EventMain

  template: 'events/event_views/eventPlacement'

  events:
    "click [data-region='eventParts'] > [data-type='attach']"         : 'showAttach'
    "click [data-region='eventParts'] [data-action='downloadAttach']" : 'downloadAttach'

  ui:
    text                        : '.text'

  templateHelpers: ->
    data: @data

  parse: ->
    @data = {}

    content   = @model.get 'content'
    headers   = @model.get 'headers'

    if not content and not headers
      throw new Error("Missing headers or content.")

    co =>
      if content.children.length
        [@data.properties, @data.attachments] = yield [
          @_getEventProperties(headers, content)
          @_getAttachments(content)
        ]

  onShow: ->
    super

    @showAttach() if @data.attachments
