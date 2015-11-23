"use strict"
DashboardWidgetsModels = require "models/dashboards/widgets.coffee"
DashboardModels = require "models/dashboards/dashboards.coffee"
StatTypes = require "models/dashboards/stattype.coffee"

require "common/backbone-paginator.coffee"

###*
 * Wrap dashboardItem and add PARAMS: periods and widgets for report generating
###
exports.Model = class DashboardReport extends App.Common.ValidationModel


  urlRoot: "#{App.Config.server}/api/Report"

  idAttribute: "REPORT_ID"

  defaults:
    DISPLAY_NAME: App.t 'dashboards.dashboards.<default>'
    DASHBOARD_ID: null

    PARAMS:
      main_period   : 0
      page:
        format      : "A4"
        orientation : "portrait"
        margin      : "1cm"

      widgets       : []

  ###*
   *  widgets models collection
  ###
  widgets : null



  # TODO: use report helpers for generating periods
  # Get default period based on all widgets
  _getDefaultPeriod: =>
    report_period = [moment(), moment().endOf('day')]
    @widgets.each (model) ->
      if model.get('STATTYPE_ID') isnt 4

        period = model.createWidgetInterval()
        report_period[0] = period[0] if period[0] and period[0].isBefore(report_period[0])
        report_period[1] = period[1] if period[1] and period[1].isAfter( report_period[1])

    report_period

  initialize: (attrs, options) ->
    super
    @widgets = options?.widgets or new DashboardWidgetsModels.Collection()
    @_dashboard = options?.dashboard or new DashboardModels.Model()

    # delegate trigger event of nested collection like bubble event
    @listenTo @widgets, 'change', =>
      @trigger 'change:widgets', arguments

    # set default attributes based on option
    @mainPeriod = @_getDefaultPeriod()
    @set("DISPLAY_NAME", @_dashboard.get("DISPLAY_NAME"))
    @set("DASHBOARD_ID", @_dashboard.get("DASHBOARD_ID"))
    @set("USER_ID"     , @_dashboard.get("USER_ID")     )

    @get("PARAMS").zone         = moment().zone() / 60
    @get("PARAMS").start_period = @mainPeriod[0].format("YYYY-MM-DD")
    @get("PARAMS").end_period   = @mainPeriod[1].format("YYYY-MM-DD")

  validation:
    # display name - by default get from DashboardItem DISPLAY_NAME
    DISPLAY_NAME: [
      {
        minLength: 1
        msg: App.t 'dashboards.dashboards.display_name_validation_error'
      }
    ]

  # TODO: use report helpers for generating periods
  _serializeWidgets: =>
    widgetsJson = []
    @widgets.each (widget) =>
      if widget.get('includeInReport') and widget.get('STATTYPE_ID') isnt 4

        if @get('PARAMS').main_period
          period = @mainPeriod
        else
          period = widget.createWidgetInterval()

        statType = StatTypes.StatTypesInstance.get(widget.get('STATTYPE_ID')).get 'STAT'
        widgetsJson.push
          name            : widget.get('DISPLAY_NAME') or ""
          typename        : App.t('dashboards.widgets', { returnObjectTrees: true })["#{statType}_name"]
          type            : statType
          id              : widget.id
          start_time      : period[0].unix() if period[0]
          end_time        : period[1].unix() if period[1]
          details         : widget.get('details')
          details_count   : widget.get('details_count')
          widget_settings : widget.get('BASEOPTIONS')
    widgetsJson

  ###*
   * TODO: think about validation errors of nested elements or use backbone-nested module
   * Check valid of super and nested collection
   * @return {Boolean}
  ###
  isValid: =>
    @widgets.isValid() and super

  save: ->
    @mainPeriod = [moment(@get('PARAMS').start_period).startOf('day'), moment(@get('PARAMS').end_period).endOf('day')]
    @get('PARAMS').name     = @get 'DISPLAY_NAME'
    @get('PARAMS').locale   = App.Session.currentUser().get('LANGUAGE')
    @get('PARAMS').widgets  = @_serializeWidgets()
    super


exports.Collection = class DashboardReports extends App.Common.BackbonePagination

  paginator_core:
    url: ->
      url_params =
        start: @currentPage * @perPage
        limit: @perPage
        filter:
          USER_ID: App.Session.currentUser().get 'USER_ID'

      "#{App.Config.server}/api/report?#{$.param url_params}" +
      if @filter then "&" + $.param(@filter) +
      if @sortRule then "&" + $.param(@sortRule)
    dataType: "json"

  model: DashboardReport

  sortCollection: (args) ->
    data = {}
    data.sort = {}
    data.sort[args.field] = args.direction
    @sortRule = data

    @fetch
      reset: true
