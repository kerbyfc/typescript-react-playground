"use strict"

require "common/backbone-tree.coffee"

exports.Model = class SystemCheckServer extends App.Common.ModelTree

  urlRoot: "#{App.Config.server}/api/systemCheck/servers"

  getName: ->
    @get 'name'

exports.Collection = class SystemCheckServers extends App.Common.CollectionTree

  model: exports.Model

  url: "#{App.Config.server}/api/systemCheck/servers"

  config: ->
    debugLevel : 0
    extensions : []
    icons: false

  parse: (response) ->
    response = response.data or response

    data = []

    for server in response
      [name, port] = server.split(':')
      data.push
        id: server
        name: name
        port: port

    data
