"use strict"

ReportRun     = require "models/reports/run.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

charts =
  barGrouped    : require "views/reports/charts/bar_grouped.coffee"
  barStacked    : require "views/reports/charts/bar_stacked.coffee"
  pie           : require "views/reports/charts/pie.coffee"
  line          : require "views/reports/charts/line.coffee"
  columnStacked : require "views/reports/charts/column_stacked.coffee"
  dialogs       : require "views/reports/charts/dialogs.coffee"

config = require('settings/config.json').reports

module.exports = class WidgetView extends Marionette.LayoutView

  template: "reports/widget"

  className: "reports-widget"

  regions:
    chart: "[data-region='chart']"

  ui:
    type   : "[data-type]"
    name   : "[data-name]"
    period : "[data-period]"
    count  : "[data-count]"
    remove : "[data-action='remove']"
    clone  : "[data-action='clone']"
    menu   : "[data-menu]"
    events : "[data-events-url]"

  events:
    "click @ui.remove" : "_remove"
    "click @ui.clone"  : "_clone"

  attrsMap:
    col: "col"
    row: "row"
    sizex: "sizex"
    sizey: "sizey"

  attributes: ->
    attrs = "data-widget": @model.cid
    _.reduce @attrsMap, (acc, prop, key) =>
      if value = @model.get("OPTIONS.grid.#{prop}")
        value = parseInt value
        if not _.isNaN value
          acc["data-#{key}"] = value
        acc
    , attrs

  ###*
   * @param {Object} options
   * @option options {String} mode
   * @option options {Backbone.Model} model - widget model
   * @option options {Backbone.Model} report - report/run model
  ###
  initialize: (options = {}) ->
    {@mode, @model, @report} = options

    @listenTo @model, "change", @update

    if @mode is "edit"
      @listenTo @model, "change", _.throttle @draw, 1500, leading: false

    @listenTo @report, "change", (model) =>
      if @mode is "edit"
        if model.hasChanged /OPTIONS/
          @update()
      else
        @update()
        @draw()

    # TODO: should be charts rerendered? example: common period
    @listenTo @report, "OPTIONS", @update

  serializeData: ->
    data = _.extend super,
      mode: @mode
      urlToEditWidget: @getEditLink()

    data

  onShow: ->
    @$el.addClass "_#{@mode}"
    @update()
    @draw()

  #############################################################################
  # PRIVATE

  _getChartData: ->
    data = if @mode is "edit"
      @_generateFakeData()
    else
      _.cloneDeep @model.getChartData()

  ###*
   * Resolve chart type by widget type and view
   * @param {String} type
   * @param {String} view
   * @return {Function}
  ###
  _resolveChartClass: (type, view) ->
    if type in ["senderReceiver", "sender", "receiver"] and
        view in ["barGrouped", "barStacked"]
      view = 'dialogs'
    charts[view]

  _getType: ->
    App.t "reports.widget.types.#{@model.get('WIDGET_TYPE')}"

  _getPeriod: ->
    # TODO: report hasnt getRunDate
    runDate = @report.getRunDate?() or moment()

    period = if @report.isCommonPeriodUsed()
      reportHelpers.captureDateToString @report.getCaptureDate(), runDate
    else
      @model.captureDateToString(runDate)

    App.t "reports.widget.range", period: period

  ###*
   * Remove widget
   * @param {jQuery.Event} e
  ###
  _remove: (e) ->
    e.preventDefault()
    @model.destroy()

  ###*
   * Clone widget
   * @param {jQuery.Event} e
  ###
  _clone: (e) ->
    e.preventDefault()
    App.vent.trigger 'reports:copy:entity', 'widget', @model

  _generateFakeData: ->
    reportHelpers.generateFakeData @report, @model

  _onChartDraw: (chart) =>
    @trigger "draw", @, chart

  #############################################################################
  # PUBLIC

  draw: (options = {}) =>
    @data = @_getChartData()

    type = _.camelCase @model.get('WIDGET_TYPE')
    view = _.camelCase @model.get('WIDGET_VIEW')

    chartView = @_resolveChartClass type, view

    view = new chartView
      data   : @data
      model  : @model
      report : @report
      mode   : @mode

    @listenTo view, "draw", @_onChartDraw

    @chart.show view

  isEmpty: ->
    _.isEmpty @_getChartData()

  hasEvents: ->
    @model.has "eventsCount"

  reflow: ->
    if view = @chart.currentView
      view.reflow()

  update: =>
    @ui.name.html @model.get("DISPLAY_NAME")
    @ui.period.html @_getPeriod()
    @ui.period.toggle not @report.isCommonPeriodUsed()
    @ui.type.html @_getType()

    if not @model.query.isAddle()
      @ui.events
        .attr "href", @getEventsLink()
        .text App.t "reports.widget.goto_events"
    else
      @ui.events
        .removeAttr "href"
        .text App.t "reports.widget.result_removed"

    # update events count
    if @mode isnt "edit"
      loading  = @report.isActive()
      canceled = @report.isCanceled() and not @hasEvents()

      # update menu
      @ui.menu.toggle not loading and not canceled

      if hasCount = @model.has "eventsCount"
        @ui.count.html App.t "events.events.events_count", cnt: @model.get("eventsCount")
      @ui.count.toggle hasCount

      # update events link
      if @model.query.isCompleted()
        @ui.events.html App.t "reports.widget.goto_events"
        @ui.events.attr "href", @getEventsLink()
      else
        @ui.events.html App.t "reports.widget.result_removed"

    @

  getSize: ->
    @chart.currentView.getSize()

  getEditLink: ->
    "/reports/#{@report.id}/widgets/#{@model.id}"

  getEventsLink: ->
    params = $.param
      widget : @model.id
      query  : @model.get("QUERY_ID")
    "/events?#{params.toUpperCase()}"
