"use strict"

require "common/backbone-paginator.coffee"

exports.Model = class Tag extends App.Common.ValidationModel

  idAttribute: "TAG_ID"

  urlRoot: "#{App.Config.server}/api/tag"

  toJSON: ->
    data = super
    data.DISPLAY_NAME = _.escape $.trim data.DISPLAY_NAME if data.DISPLAY_NAME?
    data.NOTE = _.escape $.trim data.NOTE if data.NOTE?
    data

  validation:
    DISPLAY_NAME: [
      {
        rangeLength: [1, 256]
        msg: App.t 'lists.tags.tag_display_name_length_validation_error'
      }
      {
        pattern: /^(.(?!,))*$/
        msg: App.t 'lists.tags.tag_display_name_pattern_validation_error'
      }
    ]
    NOTE: [
      {
        maxLength: 1024
        msg: App.t 'lists.tags.tag_note_length_validation_error'
      }
      {
        required: false
      }
    ]

exports.Collection = class Tags extends App.Common.BackbonePagination

  model: exports.Model

  config: {}

  initialize: (options) ->
    @source = options?.source

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/tag?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage
        sort    :
          'DISPLAY_NAME': 'asc'

      url_params['sort'] = @sortRule if @sortRule

      switch @source
        when 'query'
          url = "#{App.Config.server}/api/search?type=query&scopes=tag&"

          if @query and @query isnt ''
            url_params['query'] = @query
        when 'active'
          url_params['_CONFIG_'] = "ACTIVE"

      url += $.param(url_params)

      if @filter
        url += "&" + $.param(@filter)

      return url

    dataType: "json"

  search: (val) ->
    @currentPage = 0

    switch @source
      when 'query'
        if val isnt ''
          @query = val
        else
          delete @query
      else
        if val isnt ''
          if val.charAt(0) isnt '*'
            val = "*#{val}"

          if val.charAt(val.length-1) isnt '*'
            val = val + '*'

          @filter = _.merge @filter, filter:
            'DISPLAY_NAME': val
        else
          delete @filter.filter['DISPLAY_NAME']

    @fetch
      reset: true

  sortCollection: (args) ->
    data = {}
    data[args.field] = args.direction

    @sortRule = data

    @fetch
      reset: true

  parse: (response) ->
    @totalPages = Math.ceil(response.totalCount / @perPage)

    # Если источник коллекции тегов - табличка событий
    if @source and @source is 'query'
      response.data.tag
    else
      response.data
