"use strict"

SERVER = require('settings/config.json').server

exports.model = class DiagnosticTask extends Backbone.Model

  statuses:
    preparing : 3  # в процессе подготовки
    working   : 4  # активно работает
    done      : 5  # успешно завершено
    error     : 6  # завершено с ошибкой
    waiting   : 10 # ожидает начала исполнения
    suspend   : 11 # задача приостановлена
    canceled  : 20 # задача отменена

  getState: ->
    _.invert(@statuses)[@get "status"]

  isInProgress: ->
    state = @getState()
    if state in ['preparing', 'working', 'waiting']
      # TODO: временный кастыль, бек не меняет статус при выполнении
      if state is 'working' and @get("progress") is 100 and @hasFile()
        return false
      true
    else
      false

  getStatusText: ->
    key = "settings.diagnostic.statuses.#{@getState()}"
    if $.i18n.exists key
      @t key
    else
      ""

  getFileName: ->
    if file = @get('file')?.match(/([^\s^\/]+(?=\.(\w+)))/)
      return file[1] + ".zip"
    ""

  hasFile: ->
    @has("file")

  hasError: ->
    @has("error_message")

  stop: ->
    @save(null,
      type: "DELETE"
      disableNProgress: true
      data: ""
    )

  fetch: (opt) ->
    super _.extend disableNProgress: true, opt

exports.collection = class DiagnosticTaskList extends Backbone.Collection

  url: "#{SERVER}/api/agent/logs"

  model: exports.model

  hasProgress: ->
    for model in @models
      return true if model.isInProgress()
    return false

  start: (param) ->
    $.ajax
      url: @url
      type: "POST"
      disableNProgress: true
      data: JSON.stringify(param)
      contentType: "application/json"
      dataType: "json"
      success: (res) =>
        @at(0)?.set
          status   : @model::statuses.waiting
          progress : 0
          file     : ""

  initialize: ->
    @listenTo App.Session.user, "message", (msg) =>
      if "diagnostic_report" is msg["data"].module
        data = msg["data"].data
        @log ":update", data.progress
        @get(data.id)?.set(data)

  fetch: (opt) ->
    super _.extend disableNProgress: true, opt
