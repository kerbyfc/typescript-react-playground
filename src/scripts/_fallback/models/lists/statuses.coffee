"use strict"

require "common/backbone-paginator.coffee"

exports.Model = class IdentityStatus extends App.Common.ValidationModel

  idAttribute: "IDENTITY_STATUS_ID"

  type: "status"

  display_attr: "DISPLAY_NAME"

  urlRoot: "#{App.Config.server}/api/ldapStatus"

  toJSON: ->
    data = super
    data.DISPLAY_NAME = _.escape $.trim data.DISPLAY_NAME if data.DISPLAY_NAME?
    data.NOTE = _.escape $.trim data.NOTE if data.NOTE?
    data

  validation:
    DISPLAY_NAME: [
      {
        rangeLength: [1, 256]
        msg: App.t 'lists.statuses.status_display_name_length_validation_error'
      }
      {
        pattern: /^(.(?!,))*$/
        msg: App.t 'lists.statuses.status_display_name_pattern_validation_error'
      }
      {
        pattern: /^(?!_).*(?!_)$/
        msg: App.t 'lists.statuses.status_display_name_pattern_validation_error'
      }
    ]
    NOTE: [
      {
        maxLength: 1024
        msg: App.t 'lists.statuses.status_note_length_validation_error'
      }
      {
        required: false
      }
    ]

exports.Collection = class IdentityStatuses extends App.Common.BackbonePagination

  model: exports.Model

  initialize: (options) ->
    @source = options?.source

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/ldapStatus?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage
        sort    :
          'DISPLAY_NAME': 'asc'

      url_params['sort'] = @sortRule if @sortRule

      switch @source
        when 'query'
          url = "#{App.Config.server}/api/search?type=query&scopes=ldapStatus&"

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
