"use strict"

require "views/controls/table_view.coffee"

module.exports = class FilesView extends App.Views.Controls.ContentGrid

  getTemplate: ->
    "settings/integrity_monitoring/grid"

  ui: ->
    _.merge super(),
      enabled           : '[name="enabled"]'
      scanFiles         : '#scan-files'
      scanDesc          : '#scan_description'
      schedule          : '#schedule'
      scheduleTime      : '[name="schedule_time"]'
      scan_hint         : '#scan_hint'
      apply_results     : '#apply-files'
      button_controls   : '#button_controls'

  triggers :
    "click @ui.scanFiles"         : "scan:files"
    "click #apply-files"          : "apply:files"
    "click #save_schedule_time"   : "save:schedule"

  modelEvents:
    'sync': '_updateSettings'

  _getScanDescription: (job) ->
    switch job.status
      when 6, 20, 11
        label = App.t 'settings.integrity_files_error'
      when 5
        label = App.t 'settings.integrity_files_last_scan',
          timestamp: moment(job.time_creation / 1000000).format('DD.MM.YYYY HH:mm:ss')
      when 4, 3, 10
        label = App.t 'settings.integrity_files_scanning'

    @ui.scanDesc?.text label

  onScanStart: ->
    @_updateInfo()

  onScanFinished: ->
    @_updateInfo()

  _force_two_digits: (val) ->
    if val < 10
      "0#{ val }"
    else
      val

  onScanFiles : ->
    @jobs.scan_files()
    .done ->
      App.Notifier.showSuccess
        title: App.t "settings.integrity"
        text : App.t "settings.integrity_schedule_scan_started"
    .fail ->
      App.Notifier.showError
        title: App.t "settings.integrity"
        text: App.t "settings.integrity_schedule_scan_failed"

  onApplyFiles : ->
    @jobs.apply_files()
    .done =>
      App.Notifier.showSuccess
        title: App.t "settings.integrity"
        text : App.t "settings.integrity_schedule_save_etalon_success"

      @collection.reset([])
      @_updateInfo()
    .fail (resp)->
      if resp.responseText is 'error_save_cachets_file'
        text = App.t "settings.integrity_schedule_save_etalon_failed"
      else
        text = App.t "global.undefined_error"

      App.Notifier.showError
        title   : App.t "settings.integrity"
        text    : text

  onSaveSchedule : ->
    data = Backbone.Syphon.serialize @

    [hours, minutes] =
      data.schedule_time
      .split ":"
      .map (str) ->
        parseInt str

    MINUTES = hours * 60 + minutes

    @model.save {MINUTES: MINUTES},
      success : ->
        App.Notifier.showSuccess
          title: App.t "settings.integrity"
          text : App.t "settings.integrity_schedule_saved"
      error: ->
        App.Notifier.showError
          title: App.t "settings.integrity"
          text: App.t "settings.integrity_schedule_save_failed"

  _updateSettings: ->
    return unless App.Helpers.can({type: 'integrity', action: 'scan'})
    settings = @model.toJSON()

    time = [
      @_force_two_digits(
        Math.floor settings.MINUTES / 60
      )
    ,
      @_force_two_digits(
        settings.MINUTES % 60
      )
    ]
    .join ":"

    data =
      enabled: settings.MINUTES
      schedule_time: time

    Backbone.Syphon.deserialize @, data

    if settings.MINUTES is 0
      @ui.schedule.hide()
    else
      @ui.schedule.show()

  _updateInfo: ->
    [latest_job, previous_job] = @jobs.get_jobs_info()

    if latest_job
      # Если последний job закончил работу
      if latest_job.get('status') is 5
        @collection._fetch_by_job_id(latest_job.id)

        @_getScanDescription(latest_job.toJSON())

        @ui.scan_hint?.hide()
        @ui.apply_results?.show()
        @ui.button_controls?.show()
      else
        # Если проверка еще идет, показываем результаты предыдущей
        if previous_job and previous_job.get('status') is 5
          @collection._fetch_by_job_id(previous_job.id)

          @_getScanDescription(latest_job.toJSON())

          @ui.scan_hint?.show()
          @ui.button_controls?.hide()
        else
          @ui.button_controls?.hide()

          @ui.scanDesc.text App.t 'settings.integrity_files_scanning'
    else
      @ui.apply_results.hide()

      @log ":_updateInfo", "Can't find integrity monitoring job."

  initialize: (options) ->
    super

    @jobs = options.jobs

    @jobs.on 'reset', =>
      @_updateInfo()

  onShow : ->
    super()

    @jobs.on 'start_scan', _.bind @onScanStart, @
    @jobs.on 'scan_finished', _.bind @onScanFinished, @

    @ui.enabled.on 'change', (e) =>
      if $(e.currentTarget).prop('checked')
        @ui.schedule.show()
        @ui.scheduleTime.val('')
      else
        @ui.schedule.hide()
        @ui.scheduleTime.val('')

        @onSaveSchedule()

      @resize()

    if App.Helpers.can({type: 'integrity', action: 'scan'})
      App.Common.ValidationModel::.bind(@)

    @listenTo App.Session.currentUser(), "message", (data) =>
      if data.data.module is 'diagnostic_report'
        @_getScanDescription data.data.data

  onDestroy: ->
    if App.Helpers.can({type: 'integrity', action: 'scan'})
      App.Common.ValidationModel::.unbind(@)

    @stopListening App.Session.currentUser(), "message"
