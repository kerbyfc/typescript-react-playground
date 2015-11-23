"use strict"

helpers = require "common/helpers.coffee"
require "models/entry.coffee"

class App.Objects.Entry extends Marionette.Object

  _hash: {}

  _entry: {}

  _deleted: []

  initialize: ->
    m = App.Models.Entry
    for i of m
      attr = m[i]::idAttribute
      if attr
        type = _.snakeCase(i.replace("Item", ""))

        @_entry[type] =
          type       : type
          model      : m[i]
          collection : m[i.replace("Item", "")]
          id         : attr
          name       : m[i]::nameAttribute
          url        : m[i]::urlRoot?.split('api/').pop()

  islock: (data) ->
    return if not data or not data.type

    config = @getConfig data.type
    if config
      model = new config.model
      model.islock arguments...
    else
      helpers.islock arguments...

  can: -> not @islock arguments...

  getConfig: (model) ->
    return @_entry[model] if _.isString model
    return @_entry[model.type] if model.type
    if (id = model.idAttribute) and (name = model.nameAttribute)
      model = {}
      model[id] = '_'
      model[name] = '_'

    model  = model.toJSON() if model.toJSON
    return unless model

    for i of @_entry
      return @_entry[i] if model[@_entry[i].id] and model[@_entry[i].name]

  getData: (model) ->
    return model if model.TYPE and model.ID
    model  = model.toJSON() if model.toJSON

    config = @getConfig model
    return unless config
    type   = config.type
    id     = model[config.id]
    name   = model[config.name]

    TYPE : type
    ID   : id
    NAME : App.t "entry.#{type}.#{name}", defaultValue: name

  getImagePath: (data) ->
    model = App.request('bookworm', 'contact').findWhere mnemo: data.TYPE
    if icon = model?.get('icon') then "#{App.Config.server}/img/icon/#{icon}" else null

  getName: (model, limit) ->
    if model.ID
      if item = @get model.TYPE, model.ID
        model = item
      else
        return if model.NAME then model.NAME else ""

    name = if model.getName then model.getName() else @getData(model)?.NAME

    if limit and name then helpers.reduceString name else name

  getId: (model) ->
    @getData model
    .ID

  getType: (model) ->
    @getData model
    .TYPE

  isDeleted: (type, id) ->
    if _.isObject type
      type = arguments[0].TYPE
      id   = arguments[0].ID

    _.indexOf(@_deleted, "#{type}#{id}") isnt -1

  addDeleted: (type, id) ->
    str = "#{type}#{id}"
    @_deleted.push str if _.indexOf @_deleted, str

  add: (model) ->
    return unless model

    if model.each
      model.each (m) => @add m
      return

    if _.isArray model
      _.each model, (m) =>
        @add m.content if m.TYPE and m.content
        @add m if not m.TYPE
      return

    config = @getConfig model
    return unless config
    model  = model.attributes if model.attributes
    list = @_hash[config.type] ?= []

    o = {}
    o[config.id] = model[config.id]
    el = _.find list, o

    if el
      index = _.indexOf list, el
      list[index] = model
    else
      list.push model

  getPopoverModel: ->
    @abort()
    @get arguments..., @, true

  get: (type, id, callback, context, server) ->
    if contact = App.request('bookworm', 'contact').findWhere(mnemo: type)
      type = 'contact'
    list = @_hash[type] ?= []
    return list unless id

    context ?= @

    return if not config = @_entry[type]

    o = {}
    o[config.id] = id

    model = new config.model o
    model.type = type

    if contact
      _.extend model.attributes, contact.toJSON()
      model.attributes.id = id

    unless config
      if callback
        return callback.apply context, [null, type, id]
      else
        return null

    data      = _.find(list, o)
    isDeleted = @isDeleted(type, id)
    data = _.extend data, isDeleted: isDeleted

    if (not server and data) or (isDeleted and data)
      return data unless callback
      _.extend model.attributes, data
      return callback.apply context, [data, model]

    return unless callback

    @_xhr = model.fetch
      success: (m) ->
        callback.apply context, [m.toJSON(), arguments...]
      error: (m) ->
        callback.apply context, [error: true, arguments...]

    @_xhr?.always =>
      @_xhr = null

  remove: (model) ->
    # если передается коллекция
    if model.each
      model.each (m) => @remove m
      return

    # если передается массив моделей
    if _.isArray model
      _.each model, (m) =>
        @remove m.content if m.TYPE and m.content
        @remove m if not m.TYPE
      return

    config = @getConfig model # определяем тип сущности
    return unless config # если сущность не определена прерываем выполнение

    id = model.id or model[config.id]
    return unless list = @_hash[config.type]
    return unless list.length

    @_hash[config.type] = _.remove @_hash[config.type], (entry) ->
      # удаляем элемент с текущим id
      return false if entry[config.id] is id
      true

  abort: -> @_xhr?.abort()

  clear: (type) ->
    if type
      @_hash[type] = []
    else
      @_hash = {}
      @_deleted = []

  getModel: (data) ->
    type = data.TYPE
    o = {}
    o[@_entry[type].id] = data.ID
    new @_entry[type].model o

module.exports = App.entry = new App.Objects.Entry
