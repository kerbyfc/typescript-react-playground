"use strict"

module.exports = class TaskStatus extends Backbone.Model

  url: ->
    "#{App.Config.server}/api/crawler/task/#{@task.id}/status"

  initialize: (options) ->
    {@task} = options
