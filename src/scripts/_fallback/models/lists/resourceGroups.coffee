"use strict"

exports.Model = class ResourceGroup extends App.Common.ValidationModel

  idAttribute: "LIST_ID"

  urlRoot: "#{App.Config.server}/api/systemList"

  save: (key, val, options) ->
    if key is null or typeof key is 'object'
      for key_name in ["DISPLAY_NAME", "NOTE"]
        key[key_name] = _.escape $.trim key[key_name] if key[key_name]
    else
      if key in ['DISPLAY_NAME', 'NOTE']
        val = _.escape $.trim val

    super(key, val, options)

  getItem: ->
    node =
      title         : @get 'DISPLAY_NAME'
      tooltip       : @get 'NOTE'
      key           : @get 'LIST_ID'
      data          : @toJSON()

    return node

  validation:
    DISPLAY_NAME:
      rangeLength: [1, 256]
      msg: App.t 'lists.resources.resource_group_display_name_length_validation_error'
    NOTE: [
      {
        maxLength: 1024
        msg: App.t 'lists.resources.resource_group_note_length_validation_error'
      }
      {
        required: false
      }
    ]


exports.TreeCollection = class ResourceGroupsTree extends Backbone.Collection

  model: exports.Model

  url: "#{App.Config.server}/api/systemList?sort[DISPLAY_NAME]=ASC"

  createNested: ->
    data = []

    # Преобразовываем данные в вид для дерева
    for model in @toJSON()
      tree_node =
        title       : model.DISPLAY_NAME
        tooltip     : model.NOTE
        key         : model.LIST_ID
        data        : model

      data.push tree_node

    # Строим иерархию
    @treeData = data

  getItems: =>
    return @treeData

  initialize: ->
    @treeData = []

    @on 'add reset delete change', @createNested

exports.ListCollection = class ResourceGroupsList extends App.Common.BackbonePagination

  model: exports.Model

  paginator_core:
    url: ->
      if @type and @type is 'query'
        url = "#{App.Config.server}/api/search?" +
          "type=query&scopes=SystemList&start=#{@currentPage * @perPage}&limit=#{@perPage}"
        if @filter
          url += "&" + $.param(@filter)
        if @sortRule
          url += "&" + $.param(@sortRule)
      else
        url = "#{App.Config.server}/api/systemList?start=#{@currentPage * @perPage}&limit=#{@perPage}"
        if @filter
          url = url + "&" + $.param(@filter)
        if @sortRule
          url = url + "&" + $.param(@sortRule)

      return url

    dataType: "json"

  parse: (response) ->
    @totalPages = Math.ceil(response.totalCount / @perPage)

    if @type and @type is 'query'
      response.data.SystemList
    else
      response.data
