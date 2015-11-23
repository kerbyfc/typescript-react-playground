"use strict"

helpers = require "common/helpers.coffee"
Selection = require "models/events/selections.coffee"
QueryBuilderBase = require "views/events/query_builder/query_builder_base.coffee"

module.exports = class App.Views.Settings.ScopeDialog extends App.Helpers.virtual_class(
  QueryBuilderBase
  Marionette.ItemView
)
  template: "settings/users_and_roles/scope"

  events:
    "click ._success"       : "save"

  templateHelpers: ->
    title   : @options.title
    blocked   : @options.blocked
    conditions  : [
      'violation_level'
      'verdict'
      'persons'
      'workstations'
      'tags'
      'policies'
      'documents'
    ]

  behaviors: ->
    data = {}
    data.DISPLAY_NAME = @options.model.get 'DISPLAY_NAME'
    data.NOTE = @options.model.get 'NOTE'

    if @options.model.has('VISIBILITY_AREA_CONDITION')
      query_model = new Selection.TreeNode($.parseJSON(@options.model.get('VISIBILITY_AREA_CONDITION')).data)

    if query_model
      data = _.extend data, @parseQuery query_model.children.toJSON()
      # HACK: Персоны сервером не отдаются, поэтому делаем аттрибут персоны
      #   равным аттрибуту отправители
      data['persons'] = data['senders']

    Form:
      listen : @options.model
      syphon : data

  save: (e) ->
    e.preventDefault()

    return if helpers.islock { type: 'scope', action: 'edit' }

    data = @serialize()
    conditions = @model.createCondition data
    data.VISIBILITY_AREA_CONDITION = JSON.stringify({ data: conditions })

    isNew =  @model.isNew()
    @model.save data,
      wait: true
      success: (model, collection, options) =>
        if isNew
          @collection.add @model

        @destroy()
        @options.callback() if @options.callback
