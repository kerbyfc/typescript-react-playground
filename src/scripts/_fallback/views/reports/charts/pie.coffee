"use strict"

BaseCharts = require "views/reports/charts/base_chart.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

PIE_COLORS = [
  "#3870A7"
  "#4885C1"
  "#689ACC"
  "#88B0D7"
  "#A8C5E1"
  "#C8DAEC"
]

module.exports = class Pie extends BaseCharts

  ###*
   * @override
  ###
  chartOptions: ->
    options = _.extend super,
      chart:
        plotBackgroundColor: null
        plotBorderWidth: null
        plotShadow: false
      title:
        text: null
      tooltip:
        headerFormat: ''
        pointFormat: '{point.name}, {point.percentage:.1f}%, {point.y}'
        useHTML: true
        backgroundColor: null
        borderWidth: 0
        shadow: false
        formatter: ->
          text = @key
          if ///\s->\s///.test(text)
            text = "#{text.replace(' -> ', ' &#8594;<br/>')},<br/>"
          else
            text += ', '
          text += "#{@percentage.toFixed(1)}%, #{@y}"
          "<div class='widget-pie__tooltip'>#{text}</div>"
      plotOptions:
        pie:
          allowPointSelect: true
          cursor: 'pointer'
          dataLabels:
            distance: 10
            overflow: 'none'
            enabled: true
            style:
              fontSize: '12px'
              fontWeight: 'normal'
              color: (Highcharts.theme and Highcharts.theme.contrastTextColor) or 'black'
            useHTML: true
            formatter: ->
              chartWidth = @series.chart.chartWidth
              point = @point
              x = point.labelPos[0]
              y = point.labelPos[1]
              pos = point.labelPos[6]
              w = (pos is 'center' and chartWidth or pos is 'right' and x or chartWidth - x) - 25
              str = "<div class='widget-pie__data-label' style='max-width:#{w}px'>
                     <span class='text'>#{@key}</span>"
              if point.isShowPercentage or point.isShowValues
                str += "<span class='value'>"
                str += ", #{@percentage.toFixed(1)}%" if point.isShowPercentage
                str += ", #{@y}" if point.isShowValues
                str += "</span>"
              str += "</div>"
      series: [
        type: 'pie'
        innerSize: '70%'
        size: '65%'
        minSize: '60px'
      ]
      credits:
        enabled: false

    type = @model.get('WIDGET_TYPE')
    isShowPercentage = @model.get('OPTIONS.showPercentage')
    isShowValues = @model.get('OPTIONS.showValues')
    newData = @data.sort( (a, b) ->
      return 1 if (a.id is reportHelpers.OTHER_FIELD_FOR_MASK)
      return -1 if (b.id is reportHelpers.OTHER_FIELD_FOR_MASK)
      return -1 if (+a.value > +b.value)
      return 1 if (+a.value < +b.value)
      0
    )

    series = _.map(newData, (item, i) ->
      name: reportHelpers.resolveFieldName item.name, type
      color: PIE_COLORS[ if i < 5 then i else 5]
      isShowPercentage: isShowPercentage
      isShowValues: isShowValues
      y: +item.value
    )

    options.series[0].data = series

    options
