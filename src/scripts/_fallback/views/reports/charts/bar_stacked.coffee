"use strict"

BarGrouped = require "views/reports/charts/bar_grouped.coffee"

module.exports = class BarStacked extends BarGrouped

  itemHeight: 35

  ###*
   * @override
  ###
  chartOptions: ->
    options = _.extend super,
      plotOptions:
        bar:
          dataLabels:
            enabled: true
        series:
          stacking: 'normal'
          pointPadding: 0.09
          groupPadding: 0
          shadow: false

    options

  ###*
   * @override
  ###
  initialize: ->
    super
    @labelFormatter = @createLabelFormatter()

  ###*
   * @override
  ###
  draw: ->
    if super
      $.each @highchart.series, (i, series) ->
        $.each series.data, (j, data) ->
          if data.y is 0
            data.destroy()

