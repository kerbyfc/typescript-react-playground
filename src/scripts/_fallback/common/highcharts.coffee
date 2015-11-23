"use strict"

require "highstock"

Highcharts.theme =
  global:
    useUTC: false
  chart:
    backgroundColor: '#fff'
    style:
      fontFamily: "Arial"
  credits:
    enabled: false
  title:
    style:
      fontSize: '16px'
      fontWeight: 'normal'
      textTransform: 'uppercase'
  tooltip:
    borderWidth: 0
    shadow: true
    backgroundColor: '#fff'
    formatter: ->
      level = @series.name
      levelLocale = $.t("events.conditions.violation_level_#{level.toLowerCase()}")
      "#{@key}<br/>#{levelLocale}, #{@y}"
    style:
      color: '#000'
  legend:
    itemStyle:
      fontWeight: 'bold'
      fontSize: '12px'
  xAxis:
    labels:
      style:
        fontSize: '12px'
  yAxis:
    labels:
      style:
        fontSize: '12px'
  plotOptions:
    bar:
      animation: false
      dataLabels:
        enabled: true
        style:
          fontWeight: 'normal'
        allowOverlap: 0
    series:
      minPointLength: 3
      maxPointWidth: 45
      borderWidth: 1

Highcharts.setOptions(Highcharts.theme)
