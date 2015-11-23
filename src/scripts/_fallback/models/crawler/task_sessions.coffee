"use strict"

TaskSessionEvents = require "models/crawler/task_session.coffee"

exports.Model = class TaskSession extends Backbone.Model

  idAttribute: "guid"

  defaults:
    failedHosts       : "0"
    newFilesCount     : "0"
    newFilesSize      : "0"
    oldFilesCount     : "0"
    oldFilesSize      : "0"
    successfullHosts  : "0"

  parse: (resp) ->

    resp.Events = new TaskSessionEvents.Collection resp.Events.Event
    resp.Params = new Backbone.Model resp.Params

    resp

exports.Collection = class TaskSessions extends Backbone.Collection

  model: exports.Model

  url: ->
    throw new Error("Missing task!") unless @task
    "#{App.Config.server}/api/crawler/task/#{@task.id}/sessions"

  initialize: (options) ->
    {@task} = options

  #TODO: Add default sort

  _date_compatator: (m1, m2) ->
    date1 = moment(m1.get @_comparator_field)
    date2 = moment(m2.get @_comparator_field)
    if date1.isBefore(date2)
      -1
    else if date1.isAfter(date2)
      1
    else if date1.isSame(date2)
      0

  sortCollection: ({direction, field}) ->
    switch field
      when 'status'
        @comparator = field
      when 'startTime', 'finishedTime'
        @comparator = @_date_compatator
      when "successfullHosts", "failedHosts", "filesCount", "newFilesCount"
        @comparator = (m1, m2) ->
          n1 = parseInt m1.get @_comparator_field
          n2 = parseInt m2.get @_comparator_field
          if n1 < n2
            -1
          else if n1 > n2
            1
          else if n1 is n2
            0

    @_comparator_field = field
    @sort()

    if direction is 'desc'
      @models.reverse()
      @trigger "reset"

  config: ->
    draggable       : false
    maxViewItems    : null
    disabled        : true
    forceFitColumns : true
    default :
      sortAsc   : false
      sortCol   : "startTime"
      checkbox  : true
    columns: [
      id        : "status"
      name      : App.t 'crawler.job_launch_history_status.label'
      field     : "status"
      resizable : false
      sortable  : true
      minWidth  : 50
      cssClass  : "center"
      formatter : (row, cell, value, columnDef, dataContext) ->
        icon_class = switch( dataContext.get(columnDef.field) )
          when "0"  then "icon-play"
          when "1"  then "icon-stop"
          when "2"  then "icon-cancel"
          when "3"  then "icon-ok"

        "<i class='#{icon_class}'></i>"
    ,
      id        : "startTime"
      name      : App.t 'crawler.job_launch_history_start_date'
      field     : "startTime"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter : (row, cell, value, columnDef, dataContext) ->
        moment(dataContext.get(columnDef.field)).format('D.MM.YYYY, H:mm:ss')
    ,
      id        : "finishedTime"
      name      : App.t 'crawler.job_launch_history_end_date'
      field     : "finishedTime"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter : (row, cell, value, columnDef, dataContext) ->
        if dataContext.get(columnDef.field)
          moment(dataContext.get(columnDef.field)).format('D.MM.YYYY, H:mm:ss')
        else
          App.t "global.missing"
    ,
      id        : "successfullHosts"
      name      : App.t 'crawler.job_launch_history_successful_hosts'
      field     : "successfullHosts"
      resizable : true
      sortable  : true
      minWidth  : 50
    ,
      id        : "failedHosts"
      name      : App.t 'crawler.job_launch_history_failed_hosts'
      field     : "failedHosts"
      resizable : true
      sortable  : true
      minWidth  : 50
    ,
      id        : "filesCount"
      name      : App.t 'crawler.job_launch_history_total_files_size'
      field     : "filesCount"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter : (row, cell, value, columnDef, dataContext) ->
        """
          #{
            parseInt(dataContext.get("newFilesCount")) +
            parseInt(dataContext.get("oldFilesCount"))
          }
          /
          #{
            (
              (
                parseInt(dataContext.get("newFilesSize")) +
                parseInt(dataContext.get("oldFilesSize"))
              ) / 1024 / 1024
            )
            .toFixed(2)
          }
          #{App.t 'crawler.mb'}
        """
    ,
      id        : "newFilesCount"
      name      : App.t 'crawler.job_launch_history_new_files_size'
      field     : "new_files"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter : (row, cell, value, columnDef, dataContext) ->
        """
          #{dataContext.get("newFilesCount")}
          /
          #{
            (dataContext.get("newFilesSize") / 1024 / 1024).toFixed(2)
          }
          #{App.t 'crawler.mb'}
        """
    ]
