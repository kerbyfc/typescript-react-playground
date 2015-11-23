"use strict"

exports.Collection = class SystemChecks extends Backbone.Collection

  url: ->
    url = "#{App.Config.server}/api/systemCheck?"

    if @server
      url += "serverId=#{@server}"

    url

  model: Backbone.Model

  server: null

  refresh: ->
    $.ajax
      contentType   : "application/json"
      type          : "POST"
      url           : "#{App.Config.server}/api/systemCheck/refresh?serverId=#{@server}"

  getItems: ->
    @models
