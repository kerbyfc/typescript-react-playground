"use strict"

EventFullProperties = require "views/events/event_views/event_full_properties.coffee"
require "fancytree"

module.exports = class EventDetails extends Marionette.LayoutView

  template: "events/event_views/event_details"

  regions:
    eventProperties   : '#event_properties'

  ui:
    eventBody: '.eventDetail__body'

  templateHelpers: ->
    title: @options.title

  initialize: (options) ->
    _.extend @, _.pick options,
      'callback'
      'title'
      'service'
      'type'
      'identity'
      'formatted_text'

    event     = @model.get('event').get('mnemo')
    @headers  = _.groupBy @model.get('headers'), 'OBJECT_CONTENT_ID'

    @identity = {}

    for participant in _.union @model.get('senders'), @model.get('recipients')
      for key in participant.keys
        if event.indexOf(key.KEY_TYPE)
          @identity[key.KEY] = participant.DISPLAY_NAME

    for conflict in @model.get 'senders_conflicts'
      for sender in conflict.senders
        for key in sender.keys
          if event.indexOf(key.KEY_TYPE)
            @identity[key.KEY] = sender.DISPLAY_NAME

    for conflict in @model.get 'recipients_conflicts'
      for recipient in conflict.recipients
        for key in recipient.keys
          if event.indexOf(key.KEY_TYPE)
            @identity[key.KEY] = recipient.DISPLAY_NAME

  _parseItem: (item) ->
    elem = {}

    switch item.KIND
      when 'inline', 'multipart_alt'
        switch item.MIME
          when 'im/message', 'icq/message'
            contentHeaders = @headers[item.OBJECT_CONTENT_ID]
            contentHeaders = _.groupBy contentHeaders, 'NAME'

            from = App.t 'events.events.participant_undefined'

            if contentHeaders.from
              from = @identity[contentHeaders.from?[0].VALUE] or contentHeaders.from?[0].VALUE

            elem.title = @_getItemDescription item.MIME, partipant: from
          else
            elem.title = @_getItemDescription item.MIME
      when 'child'
        elem.title = "#{item.FILE_NAME or item.MIME} (#{App.Helpers.getBytesWithUnit(item.CONTENT_SIZE)})"

    elem.key = item.OBJECT_CONTENT_ID
    elem.data = item

    elem

  _getItemDescription: (mime, data = {}) ->
    if $.i18n.exists "events.events.part_types.#{mime}"
      App.t "events.events.part_types.#{mime}", data
    else
      mime

  parseMeta: (item) ->
    elem = @_parseItem item

    if item.children? and item.children.length
      elem.children = []

      _.each item.children, (i) =>
        elem.children.push @parseMeta i

    return elem


  onShow: ->
    content = @model.get 'content'

    @$el.find("[data-region='eventDetails']").fancytree
      icons: false
      source: [@parseMeta content]
      activate: (event, data) =>
        if data.node.data.MIME.substr(0, 5) is 'image' or data.node.data.MIME is 'application/pdf'
          url_params = $.param
            object_id : @model.id
            content_id  : data.node.data.OBJECT_CONTENT_ID

          @ui.eventBody.contents().find('html').empty()
          .append("<embed height='100%' width='100%' src='#{App.Config.server}/api/object/content?#{url_params}' />")

        else if data.node.data.MIME in ['text/html', 'http/content']

          @model.getContent(data.node.data.OBJECT_CONTENT_ID, '')
          .done (text) =>
            text = text.replace /<.*?script.*?>.*?<\/.*?script.*?>/igm, ''

            @ui.eventBody.contents().find('html').empty().css({
              "padding": "10px"
            }).html(text).find('a').attr('target', '_blank')

        else if data.node.data.MIME in ['text/plain', 'im/message', 'icq/message']
          @model.getContent(data.node.data.OBJECT_CONTENT_ID, '')
          .done (text) =>
            @ui.eventBody.contents().find('html').empty().append('<pre></pre>')
            @ui.eventBody.contents().find('html > pre').css({
              "word-break": "break-all"
              "white-space": "pre-wrap"
              "padding": "10px"
            }).text(text)

    @eventProperties.show new EventFullProperties
      model: @model
      service: @options.service
