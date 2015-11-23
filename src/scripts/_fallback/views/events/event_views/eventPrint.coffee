"use strict"

co        = require "co"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventPrint extends EventMain

  template: 'events/event_views/eventPrint'

  events:
    "click [data-region='eventParts'] > [data-type='attach']"         : 'showAttach'
    "click [data-region='eventParts'] [data-action='downloadAttach']" : 'downloadAttach'

  ui:
    text                        : '.text'

  templateHelpers: ->
    data: @data

  _parsePrintContent: (content) ->
    co =>
      grouped_content = _.groupBy content.children, 'MIME'

      if grouped_content['application/pdf']?.length
        content = grouped_content['application/pdf'][0]

      else if (
        grouped_content['application/postscript']?.length and
        grouped_content['application/postscript'][0].children?.length
      )
        content = grouped_content['application/postscript'][0].children[0]

      else if (
        grouped_content['text/pcl']?.length and
        grouped_content['text/pcl'][0].children?.length
      )
        content = grouped_content['text/pcl'][0].children[0]

      else if grouped_content['image/jpeg']
        content = grouped_content['image/jpeg'][0]

      else if grouped_content['text/plain']?.length
        content = grouped_content['text/plain'][0]

      att =
        mime        : content.MIME
        content_id  : content.OBJECT_CONTENT_ID
        size        : content.CONTENT_SIZE
        filename    : content.FILE_NAME or ''
        object_id   : content.OBJECT_ID

      if content.IS_TEXT is '0'
        att.text = yield @_findText(content)
      else
        att.text = [content.OBJECT_CONTENT_ID]

      [att]

  parse: ->
    @data = {}

    content   = @model.get 'content'
    headers   = @model.get 'headers'

    co =>
      if content.children.length
        [@data.properties, @data.attachments] = yield [
          @_getEventProperties(headers, content)
          @_parsePrintContent(content)
        ]

  onShow: ->
    super

    @showAttach() if @data.attachments
