"use strict"

require "bootstrap.datetimepicker"
require "bootstrap.datetimepicker.ru"
require "views/dashboards/widgets.coffee"
require "views/dashboards/renderers/widget.coffee"

Threat = require "models/dashboards/threat.coffee"

Widget = require "views/dashboards/renderers/widget.coffee"

exports.WidgetSettings = class ThreatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/threat_timeline/widget_settings"

exports.WidgetView = class Threats extends Widget.WidgetView

  template: "dashboards/widgets/threat_timeline/widget_view"

  defaultVisualType: 'timeline'

  drawGraphs: (data = []) ->
    if ('High' of data) or ('Medium' of data) or ('Low' of data)
      @$('#dashChartVisitors').highcharts 'StockChart',
        rangeSelector:
          enabled: false

        chart:
          height: 350

        tooltip:
          borderWidth: 0
          shadow: true
          backgroundColor: '#fff'
          formatter: ->
            _.map @points, (point) ->
              "#{App.t('dashboards.widgets.threats.' + point.series.name)} [#{moment(point.x).local().format("L LT")}] - #{point.y}"
            .join('<br>')
          style:
            color: '#000'

        yAxis:
          allowDecimals: false
          min: 0

        xAxis:
          type: 'datetime'
          gridLineWidth: 1
          min: @collection.start_date.valueOf()
          max: @collection.end_date.valueOf()
          labels:
            formatter: ->
              Highcharts.dateFormat("%b %e", @value)

        series : [
          name : 'Low'
          data : data.Low
          color: '#5EB95E'
          shadow : true
          tooltip :
            valueDecimals : 2
        ,
          name : 'Medium'
          data : data.Medium
          color: '#edc240'
          shadow : true
          tooltip :
            valueDecimals : 2
        ,
          name : 'High'
          data : data.High
          color: '#DC143C'
          shadow : true
          tooltip :
            valueDecimals : 2
        ]

        plotOptions:
          series:
            lineWidth: 2
            cursor: 'pointer'
            point:
              events:
                click: (e) =>
                  params =
                    FROM: moment(e.point.x).unix()
                    TO: moment(e.point.x).add('hours', 1).unix()
                    VIOLATION_LEVEL: e.point.series.name

                  if @collection.RULE_GROUP_TYPE
                    params['RULE_GROUP_TYPE'] = @collection.RULE_GROUP_TYPE

                  App.Routes.Application.navigate "/events?#{$.param params}", {trigger: true}
    else
      @$el.find('#dashChartVisitors').empty()
        .removeAttr('style')
        .append("<div class='widgetContent__empty'>#{App.t 'dashboards.widgets.no_items'}</div>")

  initialize: ->
    @collection = new Threat.ThreatTimeline

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  timeline: ->
    @listenTo @collection, 'sync', =>
      @drawGraphs(@collection.at(0)?.toJSON())

    @collection.fetch
      reset: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @
