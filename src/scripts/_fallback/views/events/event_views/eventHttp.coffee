"use strict"

co = require "co"
address_parser = require "addressparser"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventHTTP extends EventMain

  template: 'events/event_views/event_http'

  events:
    "click [data-region='eventParts'] li[data-type='attach']"       : 'showAttach'
    "click [data-action='downloadAttach']"                          : 'downloadAttach'
    "click [data-region='eventParts'] li:not([data-type='attach'])" : 'showMessage'

  ui:
    text                                  : '.text'
    eventToolbar                          : '.eventInfo__attachment'

  templateHelpers: ->
    data: @data

  _getEventProperties: (headers, content) ->
    properties = super

    if headers.from?[0]?
      properties.from         = address_parser(headers.from[0].VALUE)

    if headers.cc?[0]?
      properties.cc           = address_parser(headers.cc[0].VALUE)

    if headers.to?[0]?
      properties.to           = address_parser(headers.to[0].VALUE)

    if headers.subject?[0]?
      properties.subject      = headers.subject[0].VALUE

    if headers.header_content_id?
      properties.content_ids  = headers.header_content_id

    properties

  _collectHeaders: (content) ->
    properties = {}

    if content.content_headers?.length
      for header in content.content_headers
        properties[header.NAME] = header.VALUE

    properties

  parse: ->
    @data =
      content: {}
      attachments: []
      properties: {}

    content   = @model.get 'content'
    headers   = @model.get 'headers'

    # Группируем заголовки по имени
    grouped_headers = _.groupBy headers, 'NAME'

    co =>
      html = []
      properties = @_getEventProperties(grouped_headers, content)

      @data.attachments.push yield @_getAttachments(content)

      for elem in content.children when elem.KIND is 'inline'
        if elem.MIME is 'http/variables'
          html.push yield @_findText(elem)
          @data.attachments.push yield @_getAttachments(elem)
          properties = _.merge properties, @_collectHeaders(elem)

        if elem.MIME is 'http/part'
          html.push yield @_findText(elem)
          @data.attachments.push yield @_getAttachments(elem.children[0])
          properties = _.merge properties, @_collectHeaders(elem.children[0])

      html = _.flatten html
      @data.attachments = _.flatten @data.attachments
      @data.properties = properties

      if html.length
        @data.content.html = yield @model.getContent(html)

      @data.attachments = _.union @data.attachments


  showMessage: (e) ->
    e?.preventDefault()

    @data.content.html = @data.content.html.replace /<.*?script.*?>.*?<\/.*?script.*?>/igm, ''

    @ui.text.contents().find('html').empty().css({
      "padding": "10px"
    }).html(@data.content.html).find('a').attr('target', '_blank')

    $('.attachments').find('a.active').removeClass('active')
    @_hideProgress(@ui.eventToolbar.find("li .active"))

    $('.text-message > a').addClass('active')

  onShow: ->
    super

    if @data.content.html
      @showMessage()
    else
      @showAttach()
