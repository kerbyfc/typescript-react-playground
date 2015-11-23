"use strict"

require "common/backbone-paginator.coffee"

exports.Model = class FileformatItem extends Backbone.Model

  idAttribute: "format_id"

  nameAttribute: "name"

  type: "fileformat"

  urlRoot: "#{App.Config.server}/api/Bookworm/Formats"

exports.Collection = class Fileformat extends App.Common.BackboneLocalPagination

  model: exports.Model

  paginator_ui:
    firstPage   : 0
    currentPage : 0
    perPage     : 1000

  islock: (original) ->
    data = action: original if _.isString original

    if not data.action or data.action is 'show'
      data = type : 'file'

    if data.action is 'policy'
      data =
        type   : 'policy_object'
        action : 'edit'

    super data, original

  byType: (type) ->
    return @ unless type

    filtered = @filter (item) ->
      item.get("type_ref") is type

    new App.Models.File.Fileformat filtered

  buttons: [ "policy" ]

  search: (data) ->
    query = data.data?.filter?.name?.replace(/[*]/g, '')
    files = App.request('bookworm', 'fileformat').toJSON()
    files = _.where(files, type_ref: @section.id)
    if query
      files = _.filter files, (model) ->
        return true if model.name.toUpperCase().indexOf(query.toUpperCase()) >= 0
        false
    @reset files
    @trigger 'search:loading', false

  config: ->
    draggable    : false
    maxViewItems : null
    disabled     : true
    default :
      sortCol  : "VALUE"
      sortable : false
    columns: [
      id        : "name"
      name      : App.t "lists.formats.name_column"
      field     : "name"
      resizable : true
      sortable  : true
      minWidth  : 150
    ,
      id        : "mime_type"
      name      : App.t "lists.formats.mime_column"
      field     : "mime_type"
      resizable : true
      sortable  : true
      minWidth  : 150
    ,
      id        : "extensions"
      name      : App.t "lists.formats.extensions_column"
      field     : "extensions"
      resizable : true
      sortable  : true
      minWidth  : 150
    ]
