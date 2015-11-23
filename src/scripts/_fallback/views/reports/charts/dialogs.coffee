"use strict"

BaseCharts = require "views/reports/charts/base_chart.coffee"
reportHelpers = require "helpers/report_helpers.coffee"

VIOLATION_LEVEL = [
  'No'
  'Medium'
  'Low'
  'High'
]

BAR_COLORS =
  'High'    : "#FA8072",
  'Low'   : "#86B375",
  'Medium'  : "#FFBB55",
  'No'    : "#CCCCCC"

module.exports = class Dialogs extends BaseCharts

  itemHeight: 47

  types: [
    'domain',
    'email',
    'icq',
    'lotus',
    'lync',
    'pc',
    'person',
    'skype'
  ]

  ###*
   * @override
   * TODO: refactoring
  ###
  chartOptions: ->
    options = _.extend super,
      chart:
        type: 'bar'
        marginLeft: 180
      title:
        text: null
      xAxis:
        title:
          text: null
        tickLength: 0
        lineWidth: 0
        labels:
          useHTML: true
          formatter: ->
            @value.name
      yAxis:
        lineWidth: 0
        gridLineWidth: 0
        title:
          text: null
        labels:
          enabled: false
      tooltip:
        useHTML: true
        backgroundColor: null
        borderWidth: 0
        shadow: false
        formatter: @_tooltipFormatter
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

    widgetType = @model.get('WIDGET_TYPE')
    chartType = @model.get('WIDGET_VIEW')
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
    _.each(@data, (item) =>
      contact = name: item.name

      switch widgetType
        when 'sender'
          contact.sender = @_resolveContact item, 'sender'
        when 'receiver'
          contact.receiver = @_resolveContact item, 'receiver'
        when 'sender_receiver'
          usersName = item.name.split(' -> ')
          contact.sender = @_resolveContact item, 'sender', usersName[0]
          contact.receiver = @_resolveContact item, 'receiver', usersName[1]
      categories.push contact

      _.each(item.value, (value, name) ->
        (series[name] or series[name] = []).push(value)
      )
    )
    series = _.map(series, (value, name) ->
      name: name
      data: value
      color: BAR_COLORS[name]
    )
    series = _.sortBy(series, (item) ->
      ['No', 'Low', 'Medium', 'High'].indexOf(item.name)
    )

    if widgetType is 'sender_receiver'
      options.chart.marginLeft = 340

    if chartType is 'bar_stacked'
      options.plotOptions.series.stacking = 'normal'

    _isExistSender = @_isExistSender()
    _isExistReceiver = @_isExistReceiver()
    _getStyleByType = @_getStyleByType
    options.xAxis.labels.formatter = ->
      contact = @value
      contact.isExistSender   = _isExistSender
      contact.isExistReceiver = _isExistReceiver
      contact.getStyleByType  = _getStyleByType
      Marionette.Renderer.render 'reports/charts/partials/contact', contact

    isShowValues = !!@model.get('OPTIONS.showValues')
    options.plotOptions.bar.dataLabels.enabled = isShowValues

    options.series = series
    options.xAxis.categories = categories

    options

  minX: ->
    @model.get('WIDGET_TYPE') is 'sender_receiver' and 2 or 1

  #############################################################################
  # PRIVATE

  _tooltipFormatter: ->
    level = @series.name
    levelLocale = $.t("events.conditions.violation_level_#{level.toLowerCase()}")
    "
      <div class='widget-pie__tooltip'>
      #{@key.name.replace(' -> ', ' &#8594;<br/>')}<br/>
      <span>#{levelLocale}</span>, #{@y}
      </div>
    "

  _getStyleByType: (item) ->
    if item.type then "_#{item.type}" else ''

  _isExistSender: =>
    !!{'sender_receiver', 'sender'}[@model.get 'WIDGET_TYPE']

  _isExistReceiver: =>
    !!{'sender_receiver', 'receiver'}[@model.get 'WIDGET_TYPE']

  _resolveContact: (item, widgetType, altName) ->
    person = item[widgetType]

    if not person
      person = {
        name: reportHelpers.resolveFieldName altName or item.name
      }
      if item.type is 'person' and item.id isnt null
        person.id = item.id

    if not person.type
      person.type = item.type

    person.hasContactInfo = !!(person.id and ///person|group///.test(person.type))
    person

  #############################################################################
  # PUBLIC

  ###*
   * @override
  ###
  draw: ->
    if super

      chartType = @model.get('WIDGET_VIEW')
      if chartType is 'bar_stacked'

        $.each @highchart.series, (i, series) ->
          $.each series.data, (j, data) ->
            if data.y is 0
              data.destroyElements()
