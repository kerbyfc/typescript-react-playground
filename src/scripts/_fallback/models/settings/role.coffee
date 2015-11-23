"use strict"

exports.Model = class Role extends App.Common.ValidationModel

  idAttribute: "ROLE_ID"

  urlRoot: "#{App.Config.server}/api/role"

  validation:
    DISPLAY_NAME:
      required: true
      msg: App.t 'settings.roles.role_required_validation_error'

  toJSON: ->
    data = super
    data.DISPLAY_NAME = _.escape $.trim data.DISPLAY_NAME if data.DISPLAY_NAME?
    data.NOTE = _.escape $.trim data.NOTE if data.NOTE?
    data

exports.Collection = class Roles extends App.Common.BackbonePagination

  model: exports.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/role?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage
        sort    :
          'DISPLAY_NAME': 'asc'

      url_params['sort'] = @sortRule.sort or @sortRule if @sortRule

      url_params['merge_with'] = ['users']

      url += $.param(url_params)

      if @filter
        url += "&" + $.param(@filter)

      return url

    dataType: "json"
