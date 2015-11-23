"use strict"

Selection = require "models/events/selections.coffee"

exports.Model = class Scope extends App.Common.ValidationModel

  idAttribute: "VISIBILITY_AREA_ID"

  urlRoot: "#{App.Config.server}/api/visibilityArea"

  type: 'scope'

  validation:
    DISPLAY_NAME: [
      required: true
      msg: 'settings.scopes.scope_required_validation_error'
    ,
      rangeLength: [1, 256],
      msg: 'settings.scopes.scope_name_length_validation_error'
    ,
      not_unique_field: true
      msg: 'settings.scopes.scope_name_contraint_violation_error'
    ]

  islock: ->
    if @isSystem()
      return {
        key: 'is_system'
        state: 2
        message: App.t 'form.error.is_system'
      }

    super

  validate: (data) ->
    error = super

    condition = $.parseJSON(data.VISIBILITY_AREA_CONDITION)

    if condition.data.children.length is 0
      error ?= {}
      error.misc = App.t 'settings.scopes.scope_empty_contraint_violation_error'

    error

  toJSON: ->
    data = super
    data.DISPLAY_NAME = _.escape $.trim data.DISPLAY_NAME if data.DISPLAY_NAME?
    data.NOTE = _.escape $.trim data.NOTE if data.NOTE?
    data

  createCondition: (data) ->
    model = new Selection.TreeNode
      link_operator: 'and'
      children: []

    _.each data, (value, key) ->
      return if not value
      return if value.value is null or value.value is ""

      model_data = model.createModelData(key, value)

      if model_data
        model.children.add new model.children.model model_data

    return model

exports.Collection = class Scopes extends App.Common.BackbonePagination

  model: exports.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/visibilityArea?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage
        sort    :
          'DISPLAY_NAME': 'asc'

      url_params['sort'] = @sortRule if @sortRule

      url += $.param(url_params)

      if @filter
        url += "&" + $.param(@filter)

      return url

    dataType: "json"
