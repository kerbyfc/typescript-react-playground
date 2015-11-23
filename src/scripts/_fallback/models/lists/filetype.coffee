"use strict"

require "common/backbone-tree.coffee"

exports.Model = class FiletypeItem extends App.Common.ModelTree

  idAttribute: "format_type_id"

  nameAttribute: "name"

  type: 'filetype'

  urlRoot: "#{App.Config.server}/api/Bookworm/FormatTypes"

  getItem: ->
    title        : @getName()
    key          : @id
    extraClasses : '_noIcon'
    data         : @toJSON()

exports.Collection = class Filetype extends App.Common.CollectionTree

  model: exports.Model

  url: "#{App.Config.server}/api/Bookworm/FormatTypes"

  buttons: [ "policy" ]

  islock: (data) ->
    data = action: data if _.isString data

    if not data.action or data.action is 'show'
      data = type : 'file'

    if data.action is 'policy'
      data =
        type   : 'policy_object'
        action : 'edit'

    super data

  config: ->
    debugLevel : 0
