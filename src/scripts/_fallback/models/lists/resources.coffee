"use strict"

exports.Model = class Resource extends App.Common.ValidationModel

  idAttribute: "LIST_ITEM_ID"

  urlRoot: "#{App.Config.server}/api/systemListItem"

  toJSON: ->
    data = super
    data.VALUE = _.escape $.trim data.VALUE if data.VALUE?
    data

  validation:
    VALUE:
      rangeLength: [1, 256]
      msg: App.t 'lists.resources.resource_value_length_validation_error'
    NOTE: [
      {
        maxLength: 1024
        msg: App.t 'lists.resources.resource_value_note_length_validation_error'
      }
      {
        required: false
      }
    ]

exports.Collection = class Resources extends App.Common.BackbonePagination

  model: exports.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/systemListItem?start=#{@currentPage * @perPage}&limit=#{@perPage}"
      if @filter
        url = url + "&" + $.param(@filter)
      if @sortRule
        url = url + "&" + $.param(@sortRule)

      return url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 100

  filterResources: (value) ->
    $.xhrPool.abortAll()

    if value isnt ''
      if value.charAt(value.length-1) isnt '*'
        value = value + '*'

      @currentPage = 0
      @fetch
        data:
          filter:
            VALUE: "#{value}",
        reset: true
    else
      @fetch
        reset: true

  sortCollection: (args) ->
    data = {}
    data.sort = {}
    data.sort[args.field] = args.direction

    @sortRule = data

    @fetch
      reset: true
