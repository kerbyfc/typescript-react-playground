"use strict"

require "common/backbone-validation.coffee"

class App.Common.ModelTree extends App.Common.ValidationModel

  constructor: ->
    super

    @on "sync", (model, data) ->
      return unless key = model.childrenCountAttribute

      parent = model.getParentModel()
      if model.get(model.parentIdAttribute) isnt prevParentId = model.previous(model.parentIdAttribute)
        if parent
          count = +parent.get key
          parent.set key, ++count

        if prevParentId
          prev = model.collection.get prevParentId
          count = +prev.get key
          prev.set key, --count

      return unless parent
      (o = {})[model.parentIdAttribute] = parent.id
      o[model.idAttribute] = model.id
      c = parent.collection.where o
      if not c.length and parent
        count = +parent.get key
        parent.set key, ++count

    @on "destroy", (model) ->
      model.off "sync"

      return unless key = model.childrenCountAttribute
      parent = model.getParentModel()
      return unless parent
      count  = +parent.get key
      parent.set key, --count

  childrenCountAttribute: 'CHILDREN_COUNT'

  getChildrenCount: -> +@get(@childrenCountAttribute)

  isCanContainsOnlyFolders: true

  isRoot: ->
    return true if @isSystem() and @get(@nameAttribute) is '<root>'
    false

  count: (count) ->
    key = @collection.countAttribute
    return unless key
    return @set(key, count, silent: true) unless _.isUndefined count
    @get(key) or 0

  getName: ->
    name = super
    if name is "<root>"
      return App.t "select_dialog.group_empty", context: @collection.type
    name

  getParentModel: ->
    pid = @get @parentIdAttribute
    return null unless pid
    @collection.get pid

  getItem: ->
    title        : @getName()
    key          : @id
    extraClasses : if @isEnabled() then 'active' else 'inactive'
    data         : @toJSON()

  activate: -> @setStatus 'activate'

  deactivate: -> @setStatus 'deactivate'

  setStatus: (status) ->
    status = 1 - +@get('ENABLED')

    @save ENABLED: status,
      wait: true

  move: (parent) ->
    parentId = parent?.id or null

    (o = {})[@parentIdAttribute] = parentId
    @save o,
      wait: true
      success: ->
        if (
          parent and
          not parent.isRoot() and
          parent.get('ENABLED') is 0
        )
          @set ENABLED: 0

  initialize: ->
    @on "change:ENABLED", (model, status) ->
      updateChildrens = (model, value) =>
        (o = {})[@parentIdAttribute] = model.id
        children = @collection.where o

        _.each children, (child) ->
          child.set value
          updateChildrens child, value

      updateChildrens @, "ENABLED": status

class App.Common.CollectionTree extends Backbone.Collection

  url: ->
    if @type and @type is 'query'
      url = "#{App.Config.server}/api/search?type=query&scopes=#{@entryType}"
      if @filter
        url += "&" + $.param(@filter)
      if @sortRule
        url += "&" + $.param(@sortRule)

      url
    else
      "#{@model::urlRoot}?filter[TYPE]=#{@entryType}"

  get: (o, root) ->
    model = super
    return model if model
    @getRootModel() if root

  getRootModel: ->
    model = @filter (model) ->
      return true if model.isRoot()
      false

    if model.length then model[0] else null

  initialize: ->
    super
    proto = @model::
    @countAttribute = proto.countAttribute
    @entryType = proto.entryType or @model.type

  config: ->
    debugLevel : 0
    extensions : []

  getItems: =>
    pid = @model::parentIdAttribute

    data = []
    @each (model) ->
      return if model.isRoot()

      data.push model.getItem()

    map = data.reduce (map, node) ->
      map[node.key] = node
      map
    , {}

    @treeData = []

    # Строим иерархию
    for node in data
      if parent = map[node.data[pid]]
        (parent.children or (parent.children = [])).push node
      else
        @treeData.push node

    @treeData

  parse: (res) ->
    data = super
    data = data[@model::urlRoot] if @type and @type is 'query'
    data
