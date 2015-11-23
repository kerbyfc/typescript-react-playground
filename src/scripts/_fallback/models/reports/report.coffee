"use strict"

helpers        = require "common/helpers.coffee"
ReportRun      = require "models/reports/run.coffee"
TreeCollection = require "common/tree_collection.coffee"
ReportWidget   = require "models/reports/widget.coffee"

reportHelpers = require "helpers/report_helpers.coffee"

DATE_FORMAT_INPUT = reportHelpers.DATE_FORMAT_INPUT

exports.model = class ReportModel extends App.Common.ValidationModel

  ###*
   * Id attribute name
   * @type {String}
  ###
  idAttribute: "QUERY_REPORT_ID"

  ###*
   * Name attribute name
   * @type {String}
  ###
  nameAttribute: "DISPLAY_NAME"

  ###*
   * Parent attribute name
   * @see  TreeCollection
   * @type {String}
  ###
  parentIdAttribute: "FOLDER_ID"

  ###*
   * Privilege actions prefix (scope)
   * @type {String}
  ###
  priviledgesScope: "monitoring_reports"

  ###*
   * Default attributes
   * @type {Object}
  ###
  defaults:
    QUERY_REPORT_ID : "new"
    DISPLAY_NAME    : ""
    FOLDER_ID       : null
    IS_PERSONAL     : 1

    OPTIONS:
      replace: [
        category: "capture_date"
        value:
          type: "none"
      ]
      useCommonPeriod : 0

  ###*
   * Create widgets and runs collections
   * @return {ReportModel}
  ###
  constructor: (attributes, options = {}) ->
    options.parse = true

    @widgets = new ReportWidget.collection attributes?.widgets or []
    @runs    = new ReportRun.collection attributes?.reportRuns or []
    super

  ###*
   * Set reports scope as event bus for reports collection
  ###
  initialize: ->
    @on "all", (event, model, collection) ->
      App.vent.trigger "reports:report:#{event}", model, collection

  defaultParams:
    with: ['widgets']

  ###*
   * Get report with widgets, also by POST requests
   * @return {String} request url
  ###
  url: (params = {}) ->
    if params = helpers.mergeDeep @defaultParams, params
      params = $.param params

    "#{App.Config.server}/api/selectionReport#{@id and "/#{@id}" or ''}?#{params or ""}"

  ###*
   * Get url to download report
   * @param  {String} format - html, pdf, xlsx
   * @param  {Number} runId
   * @return {String} url
  ###
  downloadUrl: (runId, format) ->
    "#{App.Config.server}/api/selectionReport/generateReportFile?id=#{runId}&format=#{format}&attachment=1"

  fetchRuns: (id, options = {}) ->
    @runs.url

    _.defaults options,
      parse: true

    options.url = switch id
      when "last"
        if @isNew()
          throw new Error("Can't fetch related model for new model")
        @runs.url(@id) + "&sort[RUN_DATE]=desc&limit=1"

      when "all"
        @runs.url(@id)

      else
        @runs.model::url(id)

    @runs.fetch options

  ###*
   * Parse responce of report run request
   * @param {Object} data - response json
   * @return {Null}
  ###
  parseRunRequestResponse: (data) ->
    data.DATA ?= {}

    # TODO now id comes as string now
    data.QUERY_REPORT_RUN_ID = parseInt data.QUERY_REPORT_RUN_ID

    @runs.add new ReportRun.model data, parse: true
    while @runs.length > 50
      @runs.remove @runs.at(@runs.length - 1)

    # do not set model data
    return null

  ###*
   * Update nested collections data after parsing response
   * Determine if request was a patch request (run report) to avoid attributes mess
   * and create new nested run model
   * @param  {Object} data - response data
   * @return {Object} parsed data
  ###
  parse: (data) =>
    data = super

    if _.has data, "STATUS"
      @parseRunRequestResponse data

    else
      if runs = data.reportRuns or data.reportRunLast
        @runs.reset _.flatten [runs], parse: true
        delete data.reportRuns

      if data.widgets
        @widgets.reset data.widgets, parse: true
        delete data.widgets

      if _.isString data.OPTIONS
        data.OPTIONS = JSON.parse data.OPTIONS

      _.defaultsDeep data, @defaults

  ###*
   * Notify user about api action results
   * @param  {String} action
   * @param  {String} result - action status
  ###
  notify: notify = (method, action, result, data = {}) ->
    data = _.extend {}, @toJSON(), data
    App.Notifier[method]
      title : @t "reports.pnotify.report_#{action}", data
      text  : @t "reports.pnotify.report_#{action}_#{result}", data
      delay : data.delay or 3000

  notifySuccess : _.partial notify, "showSuccess"
  notifyError   : _.partial notify, "showError"
  notifyWarning : _.partial notify, "showWarning"
  notifyInfo    : _.partial notify, "showInfo"

  ###*
   * Destroy report
   * @note check if user can delete reports first
   * @override
  ###
  destroy: (options = {}) ->
    if  not @isNew() and
        not @can "delete"
      return false

    error = options.error
    _.extend options,
      error: =>
        # TODO: handle server error type code
        if @isActive()
          @notifyError "delete", "executing"
        error? arguments...

    super options

  ###*
   * Unset "new" id for new model and rollback it on error,
   * prepare widgets data for request payload
   * @note check if user can edit reports first
   * @override
   * @param  {Object} data
   * @param  {Object} options
   * @return {jQuery.Deferred} deferred object
  ###
  save: (data, options = {}) ->

    # FIXME: fix condition after switching to /reportRun api
    return if not options.patch and not @can "edit"

    return super if options.patch is true

    if isNew = @isNew()
      # cleanup id
      @unset @idAttribute, silent: true
      if _.isObject data
        delete data[@idAttribute]

      @once "request", =>
        if isNew
          @set @idAttribute, "new", silent: true

    origin = _.pick options, 'error', 'success'
    personalityChanged = @isDirty "IS_PERSONAL"

    _.extend options,
      success: =>
        # HACK: remove link to "new" model in collection
        if isNew
          delete @collection?._byId["new"]

        unless options.pnotify is false
          @notifySuccess "saving", "done"

        origin.success? arguments...

        if personalityChanged
          @notifyInfo "personality", "changed"

      error: (model, xhr) =>
        unless options.pnotify is false

          if _.contains xhr.responseText, "Empty visibility areas for current user"
            @notifyError "saving", "no_area"
          else
            @notifyError "saving", "failed"

        origin.error? arguments...

    super

  toJSON: (options = {}) ->
    data = super

    if options.copy
      delete data.QUERY_REPORT_ID
      delete data.FOLDER_ID

    if options.chown
      data.USER_ID = options.chown

    if not options.withoutWidgets
      @log "widgets", @widgets
      data.widgets = for widget in @widgets.models
        @prepareWidgetData widget, options
    else
      delete data.widgets

    if options.safe
      delete data.widgets if not data.widgets.length

    data

  ###*
   * Cleanup extra widget data (OPTIONS), remove "new" ids
   * Setup widget DISPLAY_NAME if it's empty
   * Setup widget query DISPLAY_NAME
   * @param  {Backbone.Model} widget
   * @return {Object} model json representation
  ###
  prepareWidgetData: (widget, options = {}) ->
    widget = widget.toJSON _.extend cleanup: true, safe: true, options

    unless $.trim widget.DISPLAY_NAME
      widget.DISPLAY_NAME = @t "reports.widget.types.#{widget.WIDGET_TYPE}"

    if query = widget.query
      if not _.isString query.QUERY
        query.QUERY = JSON.stringify query.QUERY

      widget.query.QUERY_TYPE = "report"
      widget.query.USER_ID = App.Session.currentUser().id

    widget.query.DISPLAY_NAME = "
      #{moment().format "DD.MM.YY HH:mm:ss:SSS"}
      #{@get("DISPLAY_NAME")}
      #{widget.DISPLAY_NAME}
    "

    widget

  ###*
   * Validation rules
   * @type {Object}
  ###
  validation:
    DISPLAY_NAME: [
      required    : true
      rangeLength : [3, 256]
    ]
    NOTE: [
      required    : false
      rangeLength : [3, 500]
    ]

  ###*
   * Determine if model is new
   * @override
   * @return {Boolean}
  ###
  isNew: ->
    id = @get @idAttribute
    not String(id).match(/^\d+$/)? or id is "new"

  ###*
   * Get active runs (canceling & executing)
   * @return {Array} array of run models
  ###
  getActiveRuns: (options = {}) ->
    runs = @runs.filter (run) -> run.isActive()

  getLastStatus: ->
    status = @get "lastStatus"
    if not _.isNumber status
      return -1
    status

  isActive: ->
    if @runs.length
      @getActiveRuns().length
    else
      ReportRun.model.isActive @getLastStatus()

  ###*
   * Get failed runs
   * @return {Array} array of run models
  ###
  getFailedRuns: ->
    @runs.filter (run) -> run.isFailed()

  isFailed: ->
    if @runs.length
      @getFailedRuns().length
    else
      ReportRun.model.isFailed @getLastStatus()

  ###*
   * Get last CREATED run
   * @return {Backbone.Model}
  ###
  getLastRun: ->
    @runs.last()

  isRunnedAfterChanges: ->
    if runDate = @getLastRun()?.getRunDate()
      changeDate = @getChangeDate()
      changeDate.isBefore(runDate)
    else
      false

  getChangeDate: ->
    date = moment.utc @get('CHANGE_DATE'), DATE_FORMAT_INPUT
    if date.isValid()
      date.local()
    else
      null

  ###*
   * Check if reprot is personal
   * @return {Boolean}
  ###
  isPersonal: ->
    1 is Number @get "IS_PERSONAL"

  ###*
   * Start report execution
   * @return {jQuery.Deferred}
  ###
  _execute: (options = {}) ->
    success = options.success

    @save ACTION: "run", DATA: {}, _.extend options,
      wait  : true
      patch : true

    success: (runModel) =>
      success? arguments...
      App.vent.trigger "reports:executeRun", runModel
      App.vent.trigger "reports:handle:comet:message", _.extend {}, @toJSON(), runModel.toJSON(),
        type: "running"

  ###*
   * Check if runs length limit reached, and if yes, then
   * show confirmation dialog and then execute, else - just execute
  ###
  execute: (options = {}) ->
    if @runs.length >= 50
      helpers.confirm
        title   : @t "reports.pnotify.run_execution"
        content : @t "reports.pnotify.run_execution_limit_hint"

        accept: =>
          @_execute options

    else
      @_execute options

  getQueryReplacements: ->
    @get('OPTIONS')?.replace

  isCommonPeriodUsed: ->
    !!@get('OPTIONS')?.useCommonPeriod

  getCaptureDate: ->
    children = @getQueryReplacements()

    res = _.result(_.find(children, (item) ->
      item?.category is 'capture_date'
    ), 'value')

    res or {
      type: reportHelpers.CAPTURE_DATE_TYPES.all
    }

  ###*
   * download file from server
   * @param  {Number} run id
   * @param  {String} format
   * @return {jQuery.Deferred}
  ###
  download: (runId, format) ->
    $.ajax
      url: @downloadUrl runId, format
      success: =>
        @notifyInfo "download", "queued"
      error: =>
        @notifyError "download", "failed"

  islock: (data) ->
    not @can data.action or data

  cancel: ->
    @runs.last()?.cancel()

  ###*
   * Determine action possibility
   * @note fix iterations = 3
   * @todo write tests fix iterations will be >= 4
   * @param  {String} action
   * @return {Boolean} ability decision
  ###
  can: (action) ->
    return false if @isFetching()

    if action in ["cancel", "download"]
      return @runs.last()?.can(action)

    origin = action
    action = "edit" if action in ["add", "copy", "privatize"]

    # Actions "add"/"copy" can be checked without model
    # via @collection.model::can, for example.
    # In this case @get will throw an error
    if @ instanceof exports.model
      id = @get("USER_ID")
      owner = not id or App.Session.currentUser().id is id

    access = helpers.can { type: 'report', action: action }

    # just check privileges for some actions
    if origin in ["copy", "add"]
      return access

    isActive = @isActive()

    if permission = access
      # do additional checks
      if  isActive and origin in ["edit", "delete", "execute"] or
          origin is "execute"   and not @widgets.length or
          origin is "privatize" and not owner

        permission = false

    # @log ":can", origin, permission,
    #   privilege  : "#{@priviledgesScope}:#{action}"
    #   access     : access
    #   owner      : owner or @get "USER_ID"
    #   activeRuns : activeRuns
    #   permission : permission
    #   user       : App.Session.currentUser().id
    #   report     : @id

    permission

exports.collection = class Reports extends TreeCollection

  ###*
   * Model to work with
   * @type {ReportModel}
  ###
  model: exports.model

  defaults:
    params:
      sort:
        DISPLAY_NAME: "ASC"
      with:
        ["lastStatus"]

  url: (params) ->
    if params = helpers.mergeDeep @defaults.params, @options.params, params
      params = $.param params

    "#{App.Config.server}/api/selectionReport?#{params or ""}"

  comparator: "DISPLAY_NAME"

  initialize: (models = [], options = {}) ->
    @options = options
    super

  isFolder: ->
    false

  makeKey: (model) ->
    "report:#{model.id}"

  resolveNodeAttrs: (model) ->
    model.toJSON withoutWidgets: true

  resolveNodeClass: (node, model) ->
    modifiers = ["_report"]

    unless model.get("IS_PERSONAL") > 0
      modifiers.push "_public"

    if model.isActive()
      modifiers.push "_executing"

    if model.isFailed()
      modifiers.push "_failed"

    modifiers.join " "

  rebuild: (options = {}) ->
    @_cleanup()
    @treeData = @_getNodes()
    @trigger "rebuild", @treeData unless options.silent
    @treeData
