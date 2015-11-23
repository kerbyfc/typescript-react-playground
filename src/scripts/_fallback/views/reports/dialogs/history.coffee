"use strict"

require "views/controls/table_view.coffee"

ReportRun     = require "models/reports/run.coffee"
helpers       = require "common/helpers.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

STATES = _.invert ReportRun.model::states

module.exports = class ReportHistoryView extends App.Views.Controls.TableView

  config: ->
    sortable: true

    default:
      checkbox: true
      editable: true
      sortCol: "COMPLETE_DATE"
      sortAsc: @collection.sortDirection is 'asc'

    columns:
      COMPLETE_DATE:
        name: App.t "reports.run.date_complete"
        sortable  : true
        formatter: @_completeDateFormatter

      STATUS_ICON:
        name: ''
        maxWidth: 40
        minWidth: 40
        formatter: (some..., model) ->
          if model.isFailed()
            "<i class='[ icon _error ]'></i>"
          else
            ""

#       TODO: may be reverted in TM7
#       AUTHOR:
#         name: App.t "reports.run.author"

      NOTE:
        name: App.t "reports.run.comment"
        editor: Slick.BackboneEditors.Text

  template: "reports/dialogs/history"

  ui:
    action    : "[data-action]"
    download  : "[data-action='download-variant']"
    remove    : "[data-action='remove']"

  events:
    "click [data-format]" : "_download"
    "click @ui.remove"    : "_remove"

  initialize: (options) ->
    @report = options.model
    @collection = options.collection

    # TODO: may be reverted is TM7
    # # fetch users to show author for each report run
    # @users = new User.Collection()
    # @users.fetch()
    #   .done (data) =>
    #     @collection.each @_setReportRunAuthor
    # @listenTo @collection, "change update reset", @_setReportRunAuthor

    options.config = _.merge {}, _.result(@, 'config'), options.config

    @listenTo @ , "table:select" , @_toggleActionElements
    @listenTo @ , 'inline_edit'  , @_saveEdittedItem
    @listenTo @ , "table:sort"   , @_onSort

    super

  # ###*
  # TODO: may be reverted in TM7
  #  * Set report run author (initiator)
  #  * @param {Backbone.Model} run
  # ###
  # _setReportRunAuthor: (run) =>
  #   if user = @users.get run.get "USER_ID"
  #     run.set "AUTHOR", "#{user.get "USERNAME"} - #{user.get "DISPLAY_NAME"}"

  _download: (e) ->
    e.preventDefault()

    if reportRun = @_getSelectedReportRun()
      if @report.can "download"
        @report.download reportRun.id, e.target.dataset.format

  _saveEdittedItem: (model, cell, data) ->
    model.save _.object([cell.field], [data.serializedValue]),
      showSuccess : "note_editing:done"
      showError   : "note_editing:failed"
      wait: true

  serializeData: ->
    _.extend super,
      formats: ReportRun.model::formats
      changeData: @report.getChangeDate().format(reportHelpers.DATE_FORMAT)
      isRunnedAfterChanges: @report.isRunnedAfterChanges()

  onDestroy: ->
    if Backbone.history.fragment.match /runs$/
      App.vent.trigger "nav:back", "reports"

  onShow: ->
    super
    @_toggleActionElements()
    @resize 400, 750

    if not helpers.can { type: 'report', action: "download" }
      @ui.download.remove()

  _onSort: (sortOptions) ->
    @collection.sortCollection sortOptions

  _remove: (e) ->
    e.preventDefault()
    for reportRun in @getSelectedModels()
      reportRun.destroy()
    @clearSelection()

  _toggleActionElements: ->
    @ui.remove.attr "disabled", =>
      unless @getSelectedModels().length
        return true
      null

    @ui.download.attr "disabled", =>
      unless @_getSelectedReportRun()
        return true
      null

  _getSelectedReportRun: ->
    selectedReports = @getSelectedModels()
    if selectedReports.length is 1
      if selectedReports[0].isCompleted()
        return selectedReports[0]
    null

  _completeDateFormatter: (some..., reportRun) =>
    text = if reportRun.hasCompleteDate()
      reportRun.getCompleteDate()?.format(reportHelpers.DATE_FORMAT)
    else
      state = reportRun.getState()
      options =
        errors: reportRun.get('ERRORS')
      App.t "reports.states.#{state}", options

    "<a href='/reports/#{@report.id}/runs/#{reportRun.id}' class='reports-popup__history-item' data-bypass=''>#{text}</a>"
