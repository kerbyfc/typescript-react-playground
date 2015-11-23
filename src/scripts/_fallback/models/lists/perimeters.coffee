"use strict"

require "common/backbone-paginator.coffee"

class ContactModel extends Backbone.Model

  idAttribute: 'VALUE'

class Contacts extends Backbone.Collection

  model: ContactModel

class EntriesModel extends Backbone.Model

  idAttribute: 'ENTRY_ID'

class Entries extends Backbone.Collection
  model: EntriesModel


exports.PerimeterItem = class PerimeterItem extends Backbone.Model

  type: 'perimeter'

exports.PerimeterItems = class PerimeterItems extends Backbone.Collection

  model: exports.PerimeterItem


exports.Model = class Perimeter extends App.Common.ValidationModel

  idAttribute: "PERIMETER_ID"

  urlRoot: "#{App.Config.server}/api/perimeter"

  type: 'perimeter'

  toJSON: (options) ->
    attrs = _.clone(@attributes)

    if "DISPLAY_NAME" of attrs
      attrs["DISPLAY_NAME"] = $.trim attrs["DISPLAY_NAME"]

    return attrs

  display_attr: 'DISPLAY_NAME'

  getItem: ->
    node =
      title     : @get 'DISPLAY_NAME'
      tooltip   : @get 'DISPLAY_NAME'
      key       : @get 'PERIMETER_ID'
      data      : @toJSON()

    return node

  validation:
    DISPLAY_NAME:
      rangeLength: [1, 256]

    NOTE: [
      {
        maxLength: 1024
      }
      {
        required: false
      }
    ]

  parse: (response) ->
    response = response.data ? response

    if response.entries
      unless @get("entries")?
        response.entries = new Entries response.entries[..]
      else
        @get("entries").reset response.entries[..]
        delete response.entries

    if response.contacts
      unless @get("contacts")?
        response.contacts = new Contacts response.contacts[..]
      else
        @get("contacts").reset response.contacts[..]
        delete response.contacts

    return response

exports.TreeCollection = class PerimetersTree extends Backbone.Collection

  model: exports.Model

  url: "#{App.Config.server}/api/perimeter?sort[DISPLAY_NAME]=ASC"

  createNested: ->
    data = []

    # Преобразовываем данные в вид для дерева
    for model in @toJSON()
      tree_node =
        title     : model.DISPLAY_NAME
        tooltip   : model.DISPLAY_NAME
        key       : model.PERIMETER_ID
        data      : model

      data.push tree_node

    # Строим иерархию
    @treeData = data

  getItems: =>
    return @treeData

  parse: ->
    data = super
    App.entry.add _.compact _.pluck(_.union.apply(null, _.pluck(data, 'entries')), 'entry')
    data

  initialize: ->
    @treeData = []

    @on 'add reset delete change', @createNested


exports.ListCollection = class PerimetersList extends App.Common.BackbonePagination

  model: exports.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/perimeter?start=#{@currentPage * @perPage}&limit=#{@perPage}"
      if @filter
        url = url + "&" + $.param(@filter)
      if @sortRule
        url = url + "&" + $.param(@sortRule)

      return url

    dataType: "json"
