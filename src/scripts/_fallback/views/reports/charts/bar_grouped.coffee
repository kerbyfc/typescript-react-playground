"use strict"

BaseCharts = require "views/reports/charts/base_chart.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

BAR_COLORS =
  'High'    : "#FA8072",
  'Low'   : "#86B375",
  'Medium'  : "#FFBB55",
  'No'    : "#CCCCCC"

module.exports = class BarGrouped extends BaseCharts

  itemHeight: 50

  ###*
   * @override
  ###
  chartOptions: ->
    options = _.extend super,
      chart:
        type: 'bar'
      title:
        text: null
      xAxis:
        title:
          text: null
        tickLength: 0
        lineWidth: 0
        labels:
          formatter: @labelFormatter
      yAxis:
        title:
          text: null
        labels:
          enabled: false
        gridLineWidth: 0
      plotOptions:
        bar:
          dataLabels:
            enabled: true
        series:
          pointPadding: 0
          groupPadding: 0.09
          shadow: false
      legend:
        enabled: false
      credits:
        enabled: false

    type = @model.get('WIDGET_TYPE')
    series = {}
    categories = []

    # Подготавливаем массив
    # Приводим данные к числовому типу
    for item in @data
      # Итеррация по уровням нарушений [High, Medium, Low, No]
      item.value = _.reduce item.value, (acc, value, name) ->
        val = +value.value
        acc[name] = val
        acc
      , {}

    @data = reportHelpers.sortByLevels(@data)

    # Преобразуем данные в формат highcharts
    _.each(@data, (item) ->
      categories.push reportHelpers.resolveFieldName(item.name, type)

      _.each(item.value, (value, name) ->
        (series[name] or series[name] = []).push(value)
      )
    )
    series = _.map(series, (value, name) ->
      name: name
      color: BAR_COLORS[name]
      data: value
    )
    series = _.sortBy(series, (item) ->
      ['No', 'Low', 'Medium', 'High'].indexOf(item.name)
    )

    isShowValues = !!@model.get('OPTIONS.showValues')
    options.plotOptions.bar.dataLabels.enabled = isShowValues

    options.xAxis.categories = categories
    options.series = series

    options

  ###*
   * @override
  ###
  initialize: ->
    super
    @labelFormatter = @createLabelFormatter()
