"use strict"

co        = require "co"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventIM extends EventMain

  template: 'events/event_views/eventIm'

  events:
    "click [data-region='eventParts'] > [data-type='attach']"         : 'showAttach'
    "click [data-region='eventParts'] [data-action='downloadAttach']" : 'downloadAttach'

  ui:
    text                        : '.text'

  templateHelpers: ->
    data: @data
    identity: {}
    type: @options.type

  _getAttachments: (content) ->
    co =>
      attachments = []

      for elem in content.children when elem.MIME is 'im/file'

        att =
          filename    : elem.children[0].FILE_NAME
          encrypted   : elem.children[0].ENCRYPTED
          mime        : elem.children[0].MIME
          object_id   : elem.children[0].OBJECT_ID
          content_id  : elem.children[0].OBJECT_CONTENT_ID
          size        : elem.children[0].CONTENT_SIZE_STORED

        if parseInt(elem.children[0].IS_TEXT) is 0
          att.text = yield @_findText(elem.children[0])

        attachments.push att

      attachments

  _getImMessages: (headers, content, identity) ->
    co =>
      # Сначало собираем все content_id сообщений
      msg = []
      for message in content.children when message.MIME in ['im/message', 'icq/message']
        if parseInt(message.IS_TEXT, 10) is 1
          msg.push message.OBJECT_CONTENT_ID

      if msg.length
        delimiter = App.Helpers.guid()
        text      = yield @model.getContent(msg, delimiter)
        text      = text.split(delimiter)

      headers = _.groupBy headers, 'OBJECT_CONTENT_ID'

      messages  = []
      position  = 'right'
      user      = null

      # Идем по сообщения
      for message, i in content.children when message.MIME in ['im/message', 'icq/message']
        if parseInt(message.IS_TEXT, 10) is 1
          contentHeaders = headers[message.OBJECT_CONTENT_ID]
          contentHeaders = _.groupBy contentHeaders, 'NAME'

          if contentHeaders.from
            from = identity[contentHeaders.from?[0].VALUE] or contentHeaders.from?[0].VALUE

            if user is null or user isnt from
              user = from
              if position is 'left' then position = 'right' else position = 'left'

          messages.push
            from      : from or App.t 'events.events.participant_undefined'
            date      : moment(contentHeaders.date[0].VALUE)
            text      : text[i]
            position  : position

      messages

  parse: ->
    @data = {}

    content   = @model.get 'content'
    headers   = @model.get 'headers'
    event     = @model.get('event').get('mnemo')

    if not content and not headers
      throw new Error("Missing headers or content.")

    identity = {}

    for participant in _.union @model.get('senders'), @model.get('recipients')
      for key in participant.keys
        if event.indexOf(key.KEY_TYPE)
          identity[key.KEY] = participant.DISPLAY_NAME

    for conflict in @model.get 'senders_conflicts'
      for sender in conflict.senders
        for key in sender.keys
          if event.indexOf(key.KEY_TYPE)
            identity[key.KEY] = sender.DISPLAY_NAME

    for conflict in @model.get 'recipients_conflicts'
      for recipient in conflict.recipients
        for key in recipient.keys
          if event.indexOf(key.KEY_TYPE)
            identity[key.KEY] = recipient.DISPLAY_NAME

    co =>
      if content.children.length
        [@data.properties, @data.messages, @data.attachments] = yield [
          @_getEventProperties(headers, content)
          @_getImMessages(headers, content, identity)
          @_getAttachments(content)
        ]

  onShow: ->
    super

    @showAttach() if @data.attachments.length
