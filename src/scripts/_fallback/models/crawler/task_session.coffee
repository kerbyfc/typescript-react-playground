"use strict"

exports.Model = class TaskSessionEvent extends Backbone.Model

exports.Collection = class TaskSessionEvents extends Backbone.Collection

  model: exports.Model

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
      when 'severity', 'msgId'
        @comparator = field
      when 'timestamp'
        @comparator = @_date_compatator

    @_comparator_field = field
    @sort()

    if direction is 'desc'
      @models.reverse()
      @trigger "reset"

  config: ->
    forceFitColumns : true
    draggable       : false
    maxViewItems    : null
    disabled        : true
    default :
      sortCol   : "timestamp"
    columns: [
      id        : "severity"
      name      : ''
      field     : "severity"
      sortable  : true
      resizable : false
      minWidth  : 50
      maxWidth  : 50
      formatter : (row, cell, value, columnDef, model) ->
        switch model.get(columnDef.field)
          when "0"
            "0"
          when "1"
            "1"
          when "2"
            "2"
    ,
      id        : "timestamp"
      name      : App.t 'crawler.job_events_date'
      field     : "timestamp"
      sortable  : true
      resizable : false
      minWidth  : 200
      maxWidth  : 200
      formatter : (row, cell, value, columnDef, model) ->
        moment(model.get(columnDef.field)).format('D.MM.YYYY, H:mm:ss')
    ,
      id        : "msgId"
      name      : App.t 'crawler.job_events_message.label'
      field     : "msgId"
      resizable : true
      sortable  : true
      formatter : (row, cell, value, columnDef, model) ->
        model_keys = _.keys model.toJSON()

        locale = App.t('crawler.job_events_message', { returnObjectTrees: true })

        if locale[ model.get("msgId") ]
          locale[ model.get("msgId") ]
            .replace( "{0}", model.get( model_keys[0] ) )
            .replace( "{1}", model.get( model_keys[1] ) )
    ]
