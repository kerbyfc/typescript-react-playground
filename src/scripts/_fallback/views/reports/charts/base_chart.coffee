"use strict"

highcharts    = require "common/highcharts.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

ReportRun = require "models/reports/run.coffee"

config = require('settings/config.json').reports

module.exports = class BaseChart extends Marionette.ItemView

  # Свойство определяет высоту в пикселях, для одной записи виджета.
  # Если значение задано, в зависимости от количества записей,
  # виджет растягивается по высоте
  itemHeight: null

  render_without_root: true

  chartOptions: -> {}

  template: "reports/charts/base"

  ui:
    message : "[data-message]"
    spinner : "[data-spinner]"
    chart   : "[data-chart]"

  initialize: (options = {}) ->
    {@data, @mode, @report} = options

  onDestroy: ->
    @_destroyHighchart()

  onShow: ->
    @draw()

  #############################################################################
  # PRIVATE

  _destroyHighchart: ->
    @highchart?.destroy()
    delete @highchart
    @ui.chart.empty()

  ###
   * Cut of extra long words in text message
   * @param {String} label - text message
   * @param {Object} options
   * @option options {Number} maxWordLength
   * @return {Function} text processor function
  ###
  _labelCutter: (label, options) ->
    max = options.maxWordLength or 21

    if label.length > max
      # cut every word

      wordsToCut = 0

      words = _.map label.split(/\s+/), (word) ->
        if word.length > max
          wordsToCut++
          max = max - wordsToCut * 2
          word.slice(0, max) + "…"
        else
          word

      label = words.join(" ")

      options.log? ":label", label, label.length, words

    label

  #############################################################################
  # PUBLIC

  isEmpty: ->
    _.isEmpty @data

  hasEvents: ->
    @model.has "eventsCount"

  ###*
   * Draw chart
  ###
  draw: ->
    @_destroyHighchart()

    empty = @isEmpty()

    # TODO: think about correctness of using o@report for
    # two models in depend of usage invironment
    loading  = @mode isnt "edit" and @report.isActive()
    canceled = @mode isnt "edit" and @report.isCanceled() and not @hasEvents()
    failed   = @mode isnt "edit" and @report.isFailed()

    @ui.spinner.toggle loading and not @hasEvents()
    @ui.message.hide()

    if empty

      showMessage = switch

        when not @hasEvents() and canceled
          @ui.message.html App.t "reports.widget.wasnt_executed"

        when not @hasEvents() and failed
          @ui.message.html App.t "reports.widget.execution_failed"

        when @hasEvents()
          @ui.message.html App.t "reports.widget.chart_data_is_empty"

        else
          null

      # toggle spinner and empty message
      @ui.message.toggle showMessage?

    if not empty

      options = _.result(@, "chartOptions")
      @ui.chart.highcharts options
      @highchart = Highcharts.charts[@ui.chart.data('highchartsChart')]

    @trigger "draw", @

    @highchart?

  reflow: ->
    if @highchart
      @highchart.reflow()

  getSize: ->
    size =
      x: @model.get('OPTIONS.grid.size_x') or @defaultX or 0
      y: @model.get("OPTIONS.grid.size_y") or @defaultY or 0

    # some charts have dynamic height,
    # that depends on it's content height
    if itemHeight = _.result @, "itemHeight"
      height = @data.length * itemHeight + config.widget.padding.top
      computedY = Math.ceil  height / config.widget.height
      if size.y < computedY
        size.y = computedY

    # add min and max values (size.min.x, size.max.y, ...)
    # and fix size values if they are out of bounds
    for metric in ["x", "y"]
      for type in ["min", "max"]
        if not bound = _.result @, "#{type}#{metric.toUpperCase()}"
          bound = config.widget[type][metric]

        if type is "min" and size[metric] < bound
          size[metric] = bound

        if type is "max" and size[metric] > bound
          size[metric] = bound

        (size[type] ?= {})[metric] = bound

        # for gridster coords compatibility
        size["#{type}_size_#{metric}"] = bound

      # for gridster coords compatibility
      size["size_#{metric}"] = size[metric]

    size

  createLabelFormatter: (options = {}) ->
    cutter = _.partialRight @_labelCutter, options
    -> cutter String(@value).trim()
