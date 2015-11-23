"use strict"

helpers = require "common/helpers.coffee"

exports.ServiceModel = class Service extends Backbone.Model

  idAttribute   : "name"

  type          : 'service'

exports.ServiceCollection = class Services extends Backbone.Collection

  # ************
  #  PUBLIC
  # ************
  server : null

  config: ->
    conf =
      draggable     : false
      maxViewItems  : null
      disabled      : true
      default       :
        editable    : false
        sortCol     : "name"
      columns: [
        id          : "name"
        field       : "name"
        name        : App.t 'settings.services.name'
        resizable   : true
        sortable    : true
        minWidth    : 150
      ,
        id          : "running"
        field       : "running"
        name        : App.t 'settings.services.state'
        resizable   : true
        sortable    : true
        minWidth    : 100
        formatter   : (row, cell, value, columnDef, dataContext) ->
          if dataContext.get(columnDef.field)

            """
              <div class='services--status status_running'></div>
              <span>#{App.t 'settings.services.states.running'}</span>
            """
          else

            """
              <div class='services--status status_stopped'></div>
              <span>#{App.t 'settings.services.states.stopped'}</span>
            """
      ,
        id          : ""
        name        : App.t 'settings.services.logs'
        field       : ""
        resizable   : true
        sortable    : false
        minWidth    : 100
        formatter   : (row, cell, value, columnDef, dataContext) =>
          if dataContext.get 'log_present'
            if helpers.can { type: 'service', action: 'edit' }
              url = "#{App.Config.server}/api/agent/servicelog/#{dataContext.get 'name'}?serverId=#{@server}"
              "<a href='#{url}' class='services__log_link'>#{App.t 'global.save' }</a>"
            else
              "<span href='javascript:void(0)' class='services__log_link'>#{App.t 'global.save' }</span>"
      ,
        id          : ""
        name        : App.t 'settings.services.description_column'
        field       : ""
        resizable   : true
        sortable    : false
        minWidth    : 300
        formatter   : (row, cell, value, columnDef, dataContext) ->
          locale = App.t 'settings.services.description', { returnObjectTrees: true }
          locale[dataContext.get 'name']
      ]

    if helpers.can { type: 'service', action: 'edit' }
      conf.default['checkbox'] = true

    conf

  islock: (data) ->
    data = action: 'edit'

    super data

  buttons: [ "start", "stop", "restart" ]

  execute: (command, services) ->
    defer = $.Deferred()

    data =
      SERVICES: _.map services, (service) -> service.get 'name'

    $.ajax( @url(),
      contentType: "application/json"
      method: command
      data: JSON.stringify(data))
    .done (resp) ->
      defer.resolve(resp.data)
    .fail (resp) ->
      defer.reject(resp)

    return defer.promise()

  start: (services) ->
    @execute 'START', services

  stop: (services) ->
    @execute 'STOP', services

  restart: (services) ->
    @execute 'RESTART', services

  toolbar: ->
    edit: (selected) ->
      if selected.length then return false
      true

  model   : exports.ServiceModel

  sort_dir  : 'asc'

  sort_param  : 'service'

  getSection  : -> @section

  comparator  : (a, b) ->
    name1 = a.get(@sort_param)
    name2 = b.get(@sort_param)

    if name1 < name2
      ret = -1
    else if name1 > name2
      ret = 1
    else
      ret = 0

    if @sort_dir is "desc"
      ret = -ret

    return ret

  sortCollection: (args) ->
    @sort_dir = args.direction
    @sort_param = args.field

    @sort(reset: true)

  url      : ->
    url = "#{App.Config.server}/api/agent/service"

    if @server
      url += "?serverId=#{@server}"

    url
