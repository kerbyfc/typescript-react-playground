"use strict"

class Job extends Backbone.Model

  url: ->
    if @id
      "#{App.Config.server}/api/agent/job/#{@id}?serverId=#{@collection.agent_server}"
    else
      "#{App.Config.server}/api/agent/job?serverId=#{@collection.agent_server}"

module.exports = class Jobs extends Backbone.Collection

  agent_server: null

  get_jobs_info: ->
    if @length is 0
      return [false]

    if @length is 1
      return [@at(0)]

    sorted_collection = _.sortByOrder @models, (job) ->
      job.get 'time_creation'
    , ['desc']

    if sorted_collection[0].get('status') is 5
      sorted_collection.slice 0, 1
    else
      sorted_collection.slice 0, 2

  apply_files : ->
    deferred = $.Deferred()

    [latest_job, previous_job] = @get_jobs_info()

    if latest_job and latest_job.get('status') is 5
      @get latest_job.id
      .save null,
        wait: true
        success: (collection, resp, options) =>
          # При применении результатов job сервер стирает все job-ы
          # поэтому надо рефечнуть коллекцию
          @fetch
            wait: true
            success: (collection, resp, options) ->
              deferred.resolve()
            error: (collection, resp, options) ->
              deferred.reject(resp)
        error: (collection, resp, options) ->
          deferred.reject(resp)
    else
      #TODO: Добавить обработку ошибок для джобов
      @log ":apply_files", "Can't find integrity monitoring job."

      deferred.reject()

    deferred

  _startPooling: ->
    @log ":_startPooling", "Scan started."

    @trigger 'start_scan'

    @timer = setInterval =>
      @fetch
        disableNProgress: true
        wait: true
        success: =>
          [latest_job, previous_job] = @get_jobs_info()

          if latest_job.get('status') is 5
            @_stopPooling()
          else
            @trigger 'scanning', latest_job
        error: (collection, resp, options) ->
          @log ":_startPooling", "Can't fetch scan jobs."
    , 5000

  _stopPooling: ->
    @trigger 'scan_finished'

    @log ":_stopPooling", "Scan finished."

    clearInterval @timer

  scan_files : ->
    deferred = $.Deferred()

    @log ":scan_files", "Creating scan job..."

    @create {},
      wait  : true
      success: (job) =>
        @log ":scan_files", "Scan job created."

        @_startPooling()

        deferred.resolve(job)
      erorr: (model,  resp, options) ->
        @log ":scan_files", "Failed to create scan job."

        deferred.reject(resp)

    deferred

  # **************
  #  BACKBONE
  # **************
  model : Job

  url   : ->
    "#{App.Config.server}/api/agent/job?serverId=#{@agent_server}"

  initialize: (options) ->
    {@agent_server} = options
