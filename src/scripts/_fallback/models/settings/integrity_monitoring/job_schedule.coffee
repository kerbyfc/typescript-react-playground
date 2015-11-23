"use strict"

module.exports = class Schedule extends Backbone.Model

  # **************
  #  BACKBONE
  # **************
  agent_server: null

  url: ->
    url = "#{App.Config.server}/api/agent/job_schedule?serverId=#{@agent_server}"

    url

  initialize: (options) ->
    {@agent_server} = options
