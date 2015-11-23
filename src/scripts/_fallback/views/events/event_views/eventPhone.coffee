"use strict"

co = require "co"

EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventPhone extends EventMain

  template: 'events/event_views/eventSms'

  ui:
    text                        : '.text'

  _getEventProperties: (headers, content) ->

    properties = super

    if headers.date?[0]?
      properties.date = moment headers.date[0].VALUE

    properties

  templateHelpers: ->
    data: @data
    identity: @identity

  parse: ->
    @data = {}

    content   = @model.get 'content'
    headers   = @model.get 'headers'

    if not content and not headers
      throw new Error("Missing headers or content.")

    # Группируем заголовки по имени
    headers = _.groupBy headers, 'NAME'

    co =>
      [@data.message, @data.properties] = yield [
        @model.getContent(content.children[0].OBJECT_CONTENT_ID)
        @_getEventProperties(headers, content)
      ]

      #TODO: Добавить обработку конфликтных пользователей
      if @model.get('senders').length
        @identity = @model.get('senders')[0]
      else
        @identity = _.min @model.get('senders_keys'), (key) -> parseInt(key.KEY_PRIORITY, 10)
