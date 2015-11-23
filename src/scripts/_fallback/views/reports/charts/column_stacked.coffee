"use strict"

Line = require "views/reports/charts/line.coffee"

BAR_COLORS =
  'High'    : "#FA8072"
  'Low'   : "#86B375"
  'Medium'  : "#FFBB55"
  'No'    : "#CCCCCC"

module.exports = class ColumnStacked extends Line

  ###*
   * @override
  ###
  chartOptions: ->
    _.extend super,
      chart:
        type: 'column'
      title:
        text: null
      xAxis:
        type: 'datetime',
        dateTimeLabelFormats:
          millisecond: '%d.%m.%Y'
          minute: '%H:%M'
          hour: '%H:%M',
          day: '%d.%m'
          week: '%d.%m'
          month: '%d.%m.%Y'
          year: '%Y'
          title:
            text: 'Date'
        gridLineWidth: 1
        tickLength: 0
      yAxis:
        gridLineWidth: 0
        min: 0
        title:
          text: null
      legend:
        enabled: false
      credits:
        enabled: false
      tooltip:
        headerFormat: '<span>{series.name}</span><br/>'
        pointFormat: '{point.x:%d.%m.%Y %H:%M}, {point.y}'
      plotOptions:
        lineWidth: 2
        bar:
          dataLabels:
            enabled: true
            style:
              fontWeight: 'normal'
        series:
          stacking: 'normal'
          minPointLength: 3
          pointPadding: 0
          groupPadding: 0
          borderWidth: 1
          shadow: false
