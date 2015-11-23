"use strict"

module.exports = class IntegrityFiles extends App.Common.BackbonePagination

  buttons: []

  agent_server: null

  _fetch_by_job_id: (id) ->
    @log ":_fetch_by_job_id", "Fetching files for jon #{id}"

    @url = "#{App.Config.server}/api/agent/job/#{id}"
    @fetch()

  # **********
  #  INIT
  # **********
  initialize : (options) ->
    {@agent_server} = options

    @config =
      draggable     : false
      disabled      : true
      columns : [
        id          : "status"
        field       : "status"
        formatter   : ->
          model = _.last arguments
          status = model.get "status"

          switch status
            when 2
              App.t "global.unchanged"
            when 3
              App.t "global.modified"
            when 4
              App.t "global.added"
            when 5
              App.t "global.removed"

        name        : App.t('settings.integrity_files.status')
        sortable    : false
      ,
        id          : "path"
        field       : "path"
        name        : App.t('settings.integrity_files.file')
        sortable    : false
      ,
        id          : "prev_scan_time"
        field       : "prev_scan_time"
        formatter   : ->
          model = _.last arguments
          timestamp = model.get "prev_scan_time"

          unless timestamp?
            return App.t "global.missing"

          moment timestamp/1000000
          .format "DD.MM.YYYY HH:mm:ss"

        name        : App.t('settings.integrity_files.check_date')
        sortable    : false
      ]

    super

  reset: ->
    @total_count = 0

    super


  # ***************
  #  PAGINATOR
  # ***************
  paginator_core :
    dataType  : "json"
    url       : ->
      "#{ @url }?start=#{ @currentPage * @perPage }&limit=#{ @perPage }&serverId=#{@agent_server}"
