"use strict"

exports.ServerModel = class Server extends App.Common.ModelTree

  idAttribute: "id"

  nameAttribute: "name"

  urlRoot: "#{App.Config.server}/api/agent/servers"

  getName: ->
    @get 'name'

exports.ServerCollection = class Servers extends App.Common.CollectionTree

  model: exports.ServerModel

  url: "#{App.Config.server}/api/agent/servers"

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
