"use strict"

WidgetGridView  = require "views/reports/grid.coffee"
Report          = require "models/reports/report.coffee"
reportHelpers   = require "helpers/report_helpers.coffee"

DATE_FORMAT_INPUT = reportHelpers.DATE_FORMAT_INPUT

module.exports = class ReportRunView extends Marionette.LayoutView

  template: "reports/run"

  className: "reportRun"

  regions:
    widgetGridRegion: "[data-region='widgetGrid']"

  ui:
    action      : "[data-action]"
    hint        : "[data-hint]"
    status      : "[data-status]"
    publicIcon  : "[data-public-icon]"
    reportNote  : "[data-report-note]"
    runNote     : "[data-run-note]"

  events:
    "click @ui.action": "_dispatchAction"

  initialize: (options = {}) ->
    @showLast = options.showLast
    @model    = options.model
    @report   = options.report

    @state = {}
    Object.observe @state, @_onStateChange

  serializeData: ->
    data = _.extend super,
      formats  : @model.formats
      report   : @report.toJSON()
      reportId : @report.id
      isLast   : @model.isLast()
      isRunned : @report.isRunnedAfterChanges()
    data

  onShow: ->
    @listenTo @report.runs, "change add reset", =>
      # ensure current run is last
      if @showLast
        last = @report.runs.last()
        unless @model is last
          @setup last

    @listenTo App.vent, "reports:cancelRun", @_updateToolbar

    @setup @model

  onDestroy: ->
    Object.unobserve @state, @_onStateChange

  setup: (model) ->
    if @model?
      @stopListening @model, "change", @update

    @model = model
    @listenTo @model, "change", @update

    @update()

  ###########################################################################
  # PRIVATE

  ###*
   * Check if state was change and update view according change
   * @param {Array} changes
  ###
  _onStateChange: (changes) =>
    if change = _.findWhere(changes, name: "name")
      if change.oldValue isnt change.object.name
        @log ":draw:changed", change.oldValue, change.object.name
        @updateState()

  ###*
   * Call proper method on button click
   * @param  {jQuery.Event} e
  ###
  _dispatchAction: (e) ->
    e.preventDefault()
    @[e.currentTarget.dataset.action + "Report"]? e

  ###*
   * Resolve button accessability by asking report and run models
  ###
  _updateToolbar: ->
    for action in ['edit', 'execute', 'cancel', 'download', 'delete', 'copy']
      el = @$ "[data-action='#{action}']"

      switch
        # report is canceling
        when action is 'cancel' and @model.isCanceling()
          el.show().attr "disabled", true

        when action in ['execute', 'edit', 'cancel']
          el.toggle @report.can action
          el.attr "disabled", false

        else
          el.attr "disabled", =>
            not @report.can action

  _getPeriod: ->
    reportHelpers.captureDateToString(@model.getCaptureDate(), @model.getRunDate())

  ###########################################################################
  # PUBLIC

  ###*
   * Start RUN downloading in proper format
   * @param  {jQuery.Event} e
  ###
  downloadReport: (e) ->
    @report.download @model.id, e.currentTarget.dataset.format

  ###*
   * Copy REPORT
   * @param  {jQuery.Event} e
  ###
  copyReport: (e) ->
    App.vent.trigger "reports:copy:entity", "report", @report,
      force: App.Config.reports.copyWithoutEditing

  ###*
   * Remove report or report run
   * @param  {jQuery.Event} e
  ###
  deleteReport: (e) ->
    [target, type, goAfter] = if not @report.isRunnedAfterChanges() or @model.isLast()
      [@report, "report", "reports"]
    else
      [@model, "run", "reports/#{@report.id}"]

    App.vent.trigger "reports:remove:entity", type, target,
      confirmData:
        name: @report.get "DISPLAY_NAME"

      success: ->
        App.vent.trigger "nav", goAfter

  ###*
   * Edit REPORT
   * @param  {jQuery.Event} e
  ###
  editReport: (e) ->
    App.vent.trigger "nav", "reports/#{@report.id}/edit"

  ###*
   * Start report execution
   * @param  {jQuery.Event} e
  ###
  executeReport: (e) ->
    App.vent.trigger "reports:report:run", @report

  ###*
   * Stop run
   * @param  {jQuery.Event} e
  ###
  cancelReport: (e) ->
    @model.cancel()
    @_updateToolbar()

  ###*
   * Update controls accessability and hints visibility
  ###
  update: ->
    # update accessability of buttons
    @_updateToolbar()

    # show/hide actuality hint
    @ui.hint.toggle @report.runs.length and not @model.isLast()

    @ui.publicIcon.toggleClass "_hidden", @report.isPersonal()

    # get state name
    @state.code = @model.get "STATUS"

    @ui.reportNote.html @report.get "NOTE"
    @ui.runNote.html @model.get "NOTE"

    if @model.isNew()
      @state.name = "unused"
    else
      @state.name = @model.getState()

  updateState: ->
    # update state text

    (statusText = []).push App.t "reports.states.#{@state.name}",
      completeDate: @model.getCompleteDate()?.format(reportHelpers.DATE_FORMAT)
      errors: @model.get "ERRORS"

    if @model.isCommonPeriodUsed()
      statusText.push App.t "reports.run.common_period", substr: @_getPeriod()

    @ui.status.html statusText.join "<br/>"

    grid = @widgetGridRegion.currentView

    if modelChanged = grid?.report isnt @model
      @log ":draw", "model changed", @model

    if stateChanged = @state.name in ["executing", "canceled", "error"]
      @log ":draw", "state changed", @model, @state

    # rerender only if needed: on execution start and canceling
    if modelChanged or stateChanged
      @widgetGridRegion.show new WidgetGridView
        report     : @model
        collection : @model.widgets
