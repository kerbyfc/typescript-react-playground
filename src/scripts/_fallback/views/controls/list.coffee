"use strict"

style = require "common/style.coffee"
require "views/controls/grid.coffee"
require "models/entry.coffee"

App.Views.Controls ?= {}

class App.Views.Controls.FormList extends App.Views.Controls.Grid

  template: 'controls/form_list'

  behaviors: ->
    @collection = new App.Models.Entry[App.Helpers.camelCase(@options.type, true)]

    _.extend super,
      Form:
        listen : @
        syphon : {}

  ui:
    select : 'select'
    form   : 'form'

  templateHelpers: -> type: @options.type

  initialize: (o) ->
    o.checkbox = false
    super

    _selected = _.map @selected.toJSON(), (item) ->
      item.id = item.TYPE + item.ID unless item.id
      item

    @collection.add _selected

  get: ->
    @selected.map (model) ->
      _data = model.toJSON()
      delete _data.id
      _data

  events:
    "change :input"                  : "onChange"
    "click [data-action=removeItem]" : "removeItem"
    "click :submit"                  : "onSubmit"

  onChange: (e) ->
    @trigger "form:reset"

  removeItem: (e) ->
    $el = $ e.currentTarget
    id  = $el.data 'id'
    model = @collection.get id

    @collection.remove model

    model = @selected.findWhere
      ID   : model.get('ID')
      TYPE : model.get('TYPE')

    @selected.remove model

    @trigger "change:data", @

  onSubmit: (e) ->
    data = @serialize()
    e.preventDefault()
    e.stopPropagation()

    return unless data.NAME
    data.ID = data.NAME
    data.id = data.TYPE+data.ID
    model = new @collection.model data,
      collection : @collection
      validate   : true

    if err = model.validationError
      @trigger "invalid", @, err
    else
      length = @collection.length
      @collection.add model
      @selected.add model.toJSON()

      @trigger "change:data", @

      if length isnt @collection.length
        Backbone.Syphon.deserialize @, {}
