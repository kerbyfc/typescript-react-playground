"use strict"

ReportWidget  = require "models/reports/widget.coffee"

helpers       = require "common/helpers.coffee"
reportHelpers = require "helpers/report_helpers.coffee"
storage       = require "local-storage"

DATE_FORMAT_INPUT = reportHelpers.DATE_FORMAT_INPUT

exports.model = class ReportRun extends Backbone.Model

  ###*
   * Methods to be used as static
   * @note used by report model
  ###
  staticMethods = [
    'isActive'
    'isFailed'
  ]

  # use some methods as static methods
  for method in staticMethods
    do (method) =>
      @[method] = => @::[method] arguments...

  idAttribute : "QUERY_REPORT_RUN_ID"

  formats:
    xls  : "Excel 2003 (xls)"
    xlsx : "Excel 2007 (xlsx)"
    html : "HTML"
    pdf  : "PDF"

  defaults: ->
    QUERY_REPORT_ID     : null
    QUERY_REPORT_RUN_ID : null
    USER_ID             : App.Session.user.id

    COMPLETE_DATE : null
    ERRORS        : null
    LAYOUT        : null
    NOTE          : null
    RUN_DATE      : null

    DATA   : {}
    STATUS : 0

  states:
    created   : 0
    executing : 1
    completed : 2
    error     : 3
    canceled  : 4

  url: (id = @id) ->
    "#{App.Config.server}/api/selectionReportRun#{id and "/#{id}" or ''}"

  constructor: (attributes = {}) ->
    @widgets = new ReportWidget.collection attributes?.widgets or []
    super

  initialize: ->
    @on "change:STATUS", @triggerStatus

    @on "change", =>
      if @getState() in ["completed", "canceled", "error"]
        delete @_canceling

  ###*
   * Check fi model is new
   * @return {Boolean}
  ###
  isNew: (id = @get @idAttribute) ->
    not String(id).match(/^\d+$/)? or id is "new"

  hasData: ->
    data = @get("DATA")
    data and _.size(data) > 0

  ###*
   * Parse data, create widgets collection
   * @param  {Object} data
   * @return {Object} parsed data
  ###
  parse: (data) ->
    data = super

    data = _.defaults data, @defaults

    if _.isString data.DATA
      data.DATA = JSON.parse(data.DATA)

    @parseErrors data

    if data.DATA?.OPTIONS
      options = data.DATA.OPTIONS
      data.DATA.OPTIONS = if typeof options is 'string'
        JSON.parse(options)
      else
        options

    if data.DATA?.widgets
      @widgets.reset data.DATA.widgets, parse: true
      delete data.DATA.widgets

    data

  #############################################################################
  # PUBLIC

  ###*
   * Notify about STATUS was change with global event bus
  ###
  triggerStatus: =>
    if id = @get "QUERY_REPORT_ID"
      # TODO: write global storage
      if node = App.request "reports:tree:get:node", "report:#{id}"
        status = @get "STATUS"
        data =
          report : node.data.model
          run    : @
          node   : node
          status : _.findKey @states, (code) -> code is status

        @log ":changeStatus", data
        App.vent.trigger "reports:report:change:status", data


  getStatus: ->
    @get("STATUS")

  getState: (status = @getStatus()) =>
    _.findKey @states, (_code) ->
      status is _code

  ###*
   * Check if run is last
   * @return {Boolean}
  ###
  isLast: ->
    @collection and @collection.length and @collection.last() is @


  ###*
   * Check if run is active (executing or queued/executing)
   * @return {Boolean}
  ###
  isActive: (status = @getStatus()) =>
    @isExecuting status

  ###*
   * Check if run is executing/queued
   * @note run is active with 'created' state, as we don't
   *   just create runs without it's execution (formal state)
   * @return {Boolean}
  ###
  isExecuting: (status = @getStatus()) =>
    status in [@states.executing, @states.created]

  ###*
   * Check if run is canceling
   * @return {Boolean}
  ###
  isCanceled: (status = @getStatus()) =>
    status is @states.canceled

  ###*
   * Check if run was failed
   * @return {Boolean}
  ###
  isFailed: (status = @getStatus()) =>
    status is @states.error

  ###*
   * Check if run was completed
   * @return {Boolean}
  ###
  isCompleted: (status = @getStatus()) =>
    status is @states.completed

  ###*
   * Translate error code to readable text message
   * @param {Object} data - model data
  ###
  parseErrors: (data) ->
    if data.ERRORS?.match /visibility area/
      data.ERRORS = @t "reports.run.empty_areas"
    data

  getQueryReplacements: ->
    @get('DATA')?.OPTIONS?.replace

  isCommonPeriodUsed: ->
    !!@get('DATA')?.OPTIONS?.useCommonPeriod

  getCaptureDate: ->
    children = @getQueryReplacements()

    res = _.result(_.find(children, (item) ->
      item?.category is 'capture_date'
    ), 'value')

    res or {
      type: reportHelpers.CAPTURE_DATE_TYPES.all
    }

  ###*
   * Determine if action can be applyed with run
   * @param  {String} action
   * @return {Boolean} ability decision
  ###
  can: (action) ->
    origin = action
    action = "execute" if action is "cancel"

    access = helpers.can { type: 'report', action: action }

    if access
      return switch origin
        when "download"
          not @isActive() and @getCompletedWidgets().length > 0

        when "cancel"
          @getRunDate() and @isActive() and not @isCanceling()

        when "execute"
          not @can("cancel")

        when "delete"
          not @isActive()

        else
          false

    false

  getCompletedWidgets: ->
    @widgets.filter (widget) ->
      not _.isEmpty widget.getChartData()


  isCanceling: ->
    @_canceling?

  ###*
   * Cancel report execution
   * @return {jQuery.Deferred} promise
  ###
  cancel: ->
    data =
      STATUS: @states.canceled

    # do not update model attrs,
    # it should be done be comet
    @sync "update", @, attrs: data

    @_canceling = true
    App.vent.trigger "reports:cancelRun"

  save: (attrs, options = {}) ->
    {success, error} = options
    if not @isNew()
      super attrs, _.extend options,
        success: =>
          if options.showSuccess
            @notifySuccess options.showSuccess.split(":")...
          success? arguments...
        error: =>
          if options.showError
            @notifyError options.showError.split(":")...
          error? arguments...
    else
      super

  ###*
   * Notify user about api action results
   * @param  {String} action
   * @param  {String} result - action status
  ###
  notify: notify = (method, action, result, data = {}) ->
    data = _.extend {}, @toJSON(), data

    # extend run data with report data
    # TODO: use global storage
    if node = App.request "reports:tree:get:node", "report:#{@get "QUERY_REPORT_ID"}"
      _.extend data, node.data.model.toJSON withoutWidgets: true

    App.Notifier[method]
      title : @t "reports.pnotify.run_#{action}", data
      text  : @t "reports.pnotify.run_#{action}_#{result}", data
      delay : data.delay or 3000

  notifySuccess : _.partial notify, "showSuccess"
  notifyError   : _.partial notify, "showError"
  notifyWarning : _.partial notify, "showWarning"

  getDate: (key) ->
    date = @get(key)
    if date
      date = moment.utc(date, DATE_FORMAT_INPUT)
      if date.isValid()
        return date.local()
    null

  getRunDate: ->
    @getDate "RUN_DATE"

  getCompleteDate: ->
    @getDate "COMPLETE_DATE"

  hasCompleteDate: ->
    @get('COMPLETE_DATE')?


exports.collection = class ReportRunsCollection extends Backbone.Collection

  model: exports.model

  sortDirection: 'desc'

  urlRoot: "#{App.Config.server}/api/selectionReportRun"

  url: (reportId) ->
    url = @urlRoot + "?filter[USER_ID]=#{App.Session.currentUser().id}"
    if "#{reportId}"
      url += "&filter[QUERY_REPORT_ID]=#{reportId}"
    url

  comparator  : (run1, run2) ->
    sort = if run1.getRunDate() <= run2.getRunDate() then -1 else 1
    if @sortDirection isnt 'asc'
      sort *= -1
    sort

  sortCollection: (sortOptions) ->
    @sortDirection = sortOptions.direction
    @sort()

  get: (id) ->
    if id is "last"
      @last()
    else
      super

  last: ->
    if @models.length
      if @sortDirection is "asc"
        super
      else
        @first()
    else
      null
