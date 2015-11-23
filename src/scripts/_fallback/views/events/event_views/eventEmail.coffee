"use strict"

address_parser = require "addressparser"
co = require "co"
EventMain = require "views/events/event_views/event.coffee"

module.exports = class EventEmail extends EventMain

  className: 'eventDetail__contentWrap'

  template: 'events/event_views/eventEmail'

  ui:
    text          : '.text'
    eventToolbar  : '.eventInfo__attachment'

  defaults:
    view  : 'html'

  events:
    "click [data-action='show_as']"                                   : 'showMessage'
    "click [data-region='eventParts'] > li:not([data-type='attach'])" : 'showMessage'
    "click [data-region='eventParts'] > li[data-type='attach']"       : 'showAttach'
    "click [data-action='downloadAttach']"                            : 'downloadAttach'

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

  _getTextPart: (content) ->
    text_part = []

    for elem in content.children when elem.MIME is 'text/plain' and elem.KIND is 'inline'
      text_part.push elem.OBJECT_CONTENT_ID


    if text_part.length
      @model.getContent text_part, ''

  _getHtmlPart: (content, attachments, properties, object_id) ->
    co =>
      promises = []

      for elem in content.children when elem.MIME is 'text/html' and elem.KIND is 'inline'
        promises.push @model.getContent elem.OBJECT_CONTENT_ID, 'html'

      html = (yield promises).join('')

      html = html.replace /<.*?script.*?>.*?<\/.*?script.*?>/igm, ''

      if properties.content_ids
        html = html.replace /cid:([A-Za-z0-9._%@-]+)/g, ($0, $1) ->
          attach = _.where properties.content_ids, {VALUE: "<#{decodeURIComponent($1)}>"}

          if attach.length
            att = _.where attachments, {content_id: attach[0].OBJECT_CONTENT_ID}
            attachments = _.without attachments, att[0]

            # формируем url
            url_params = $.param
              object_id: object_id
              content_id: attach[0].OBJECT_CONTENT_ID

            return "#{App.Config.server}/api/object/content?#{url_params}"
          else
            return "#{$0}"

      {html: html, attachments: attachments}

  showMessage: (e) ->
    e.preventDefault()

    if $(e.target).hasClass('caret') then return

    $elem = $(e.currentTarget)

    if $elem.attr('data-action') is 'show_as'
      e.stopPropagation()

      $elem.closest('.btn-group').removeClass('open')
      $("[data-region='eventParts']").find('li.active').removeClass('active')
      $elem.closest('.dropdown-menu').closest('li').addClass('active')

      @showContent $elem.data('show')

    else
      @showContent()

  parse: ->
    @data =
      content: {}

    # Получаем данные из модели
    content   = @model.get 'content'
    headers   = @model.get 'headers'
    object_id = @model.id

    # Группируем заголовки по имени
    headers = _.groupBy headers, 'NAME'

    co =>
      [@data.properties, @data.attachments] = yield [
        @_getEventProperties(headers, content)
        @_getAttachments(content)
      ]

      d = yield [
        @_getHtmlPart(content, @data.attachments, @data.properties, object_id)
        @_getTextPart(content)
      ]

      @data.content.text = d[1] if d[1]
      @data.content.html = d[0].html if d[0].html
      @data.attachments = d[0].attachments

  showContent: (content_type = @defaults.view) ->
    # cancel previous request
    $.xhrPool.abortAll()

    $activeElement = @ui.eventToolbar.find("li .active")
    @ui.eventToolbar.find(".dropdown-menu li").removeClass('active')
    @_hideProgress($activeElement)
    @ui.eventToolbar.find("[data-show='#{content_type}']").closest('li').addClass('active')

    _text_attr = @ui.text.contents().find('html')

    if content_type is 'html' and @data.content.html
      @content = @data.content.html
      @showed_chunk = -1
    else if @data.content.text
      @content = @chunkData(@data.content.text, 1024 * 25)
      @showed_chunk = 0
    else
      @content = ""
      @showed_chunk = -1


    if @showed_chunk is -1
      _text_attr.empty().css({
        "padding": "10px"
      }).html(@content).find('a').attr('target', '_blank')
    else
      _text_attr.empty().append('<pre></pre>')
      @ui.text.contents().find('html > pre').css({
        "word-break": "break-all"
        "white-space": "pre-wrap"
        "padding": "10px"
      }).text(@content[0])

  onShow: ->
    super

    # По умолчанию показываем текстовый контент
    @showContent()
