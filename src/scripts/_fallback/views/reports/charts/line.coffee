"use strict"

BaseCharts    = require "views/reports/charts/base_chart.coffee"
reportHelpers = require "helpers/report_helpers.coffee"
config        = require("settings/config").reports.widget

BAR_COLORS =
  'High'   : "#FA8072"
  'Low'    : "#86B375"
  'Medium' : "#FFBB55"
  'No'     : "#CCCCCC"
  'All'    : "#CCCCCC"

VIOLATION_LEVEL = [
  'All'
  'No'
  'Medium'
  'Low'
  'High'
]

# TODO: refactoring
dateTimeFormater = (->
  yearToOutput = (startDate, str) ->
    if isChangeYear or startDate.year() isnt currentYear
      return "#{str} #{startDate.format("YYYY")}"
    str

  hoursFormatter = (startDate) ->
    "#{startDate.format("HH:mm")} #{dayWeeksFormatter(startDate)}"

  dayWeeksFormatter = (startDate) ->
    yearToOutput(startDate, startDate.format("dd DD MMM"))

  weeksFormatter = (startDate) ->
    dateFormat = "DD MMM"
    endDate = startDate.clone().day(7)
    if startDate.year() is endDate.year()
      if startDate.month() is endDate.month()
        str = "#{startDate.format("DD")} - #{endDate.format(dateFormat)}"
      else
        str = "#{startDate.format("DD MMM")} - #{endDate.format(dateFormat)}"
    else
      str = "#{startDate.format(dateFormat)} - #{endDate.format(dateFormat)}"
    yearToOutput(startDate, str)

  quartersFormatter = (startDate) ->
    str = {1: "I", 2: "II", 3: "III", 4: "IV"}[startDate.quarter()]
    yearToOutput(startDate, "#{str} #{$.t('reports.widget.grouping.quarter').toLowerCase()}")

  monthsFormatter = (startDate) ->
    yearToOutput(startDate, startDate.format("MMM"))

  isChangeYear = null
  currentYear = null

  formatters = {
    milliseconds:     "HH:mm"
    seconds:          "HH:mm"
    minutes:          "HH:mm"
    minutes_days:     hoursFormatter
    hours:            "HH:mm"
    days:             dayWeeksFormatter
    days_weeks:       weeksFormatter
    days_months:      monthsFormatter
    weeks:            weeksFormatter
    weeks_days:       weeksFormatter
    months:           monthsFormatter
    months_days:      monthsFormatter
    quarters:         quartersFormatter
    quarters_months:  quartersFormatter
    quarters_days:    quartersFormatter
    years_days:       "YYYY"
    years_years:      "YYYY"
  }

  return (timestamp, axis, dateTimeLabelFormat) ->
    options = axis.options
    dateTime = moment.utc(timestamp).local()
    currentYear = moment().year()
    groupingByPeriod = options.groupingByPeriod
    isChangeYear = options.isChangeYear
    typeFormatter = if dateTimeLabelFormat then "#{groupingByPeriod}_#{dateTimeLabelFormat}" else groupingByPeriod
    methodFormatter = formatters[typeFormatter] or formatters[dateTimeLabelFormat]

    if typeof methodFormatter is 'function'
      methodFormatter(dateTime)
    else
      dateTime.format(methodFormatter)
)()

xAxisTickPositioner = (min, max) ->
  axis = @
  options = axis.options
  normalizedTickInterval = axis.normalizeTimeTickInterval(axis.tickInterval, options.units)
  ticks = @getTimeTicks(normalizedTickInterval, min, max, options.startOfWeek, axis.ordinalPositions, axis.closestPointRange, true)
  len = ticks.length

  if len is 1
    @options.startOnTick = false
    @options.endOnTick = false

  # register information for label formatter
  ticks.info =
    higherRanks: normalizedTickInterval.higherRanks
    unitName: normalizedTickInterval.unitName

  unitName = reportHelpers.dateTimeUnitsToMomentFormat(normalizedTickInterval.unitName)

  minDate = moment.utc(axis.dataMin).local().startOf(unitName)
  firstTickDate = moment.utc(ticks[0]).local()
  firstTickDiff = firstTickDate.diff(minDate, unitName)
  if firstTickDiff < 0
    ticks[0] = minDate.valueOf()

  maxDate = moment.utc(axis.dataMax).local().startOf(unitName)
  lastTickDate = moment.utc(ticks[len - 1]).local()
  lastTickDiff = lastTickDate.diff(maxDate, unitName)
  if lastTickDiff > 0
    ticks[len - 1] = maxDate.valueOf()

  ticks

module.exports = class Line extends BaseCharts

  chartOptions: ->
    options = _.extend super,

      title:
        text: null

      rangeSelector:
        selected: 1

      xAxis:
        type: 'datetime'
        minorGridLineWidth: 0,
        minorTickInterval: 'auto',
        minorTickLength: 3,
        minorTickWidth: 1
        dateTimeLabelFormats: {
          'millisecond'
          'second'
          'minute'
          'hour'
          'day'
          'week'
          'month'
          'year'
        }
        gridLineWidth: 1
        showFirstLabel: true
        showLastLabel: true
        startOnTick: true
        endOnTick: true
        tickPositioner: xAxisTickPositioner
        labels:
          rotation: -90
          formatter: ->
            dateTimeFormater(@value, @axis, reportHelpers.dateTimeUnitsToMomentFormat @dateTimeLabelFormat)
      yAxis:
        allowDecimals: false
        gridLineWidth: 0
        min: 0
        title:
          text: null
      legend:
        enabled: false
      credits:
        enabled: false
      tooltip:
        useHTML: true
        formatter: ->
          xIndex = @point.index
          #yIndex = @series.index
          points = @point.series.yAxis.series
          value = @y

          levels = []
          for yPoint in points
            if yPoint.processedYData[xIndex] is value
              levelLocale = $.t("events.conditions.violation_level_#{yPoint.name.toLowerCase()}")
              levels.push("<span style='color: #{yPoint.color}'>&#9679;</span> #{levelLocale}, #{value}")

          dateTime = dateTimeFormater(@key, @series.xAxis)

          "#{dateTime}<br/>#{levels.join('<br/>')}"

      plotOptions:
        lineWidth: 2
        line:
          marker:
            enabled: false

    addEmptyDate = (date) ->
      for name in VIOLATION_LEVEL
        (series[name] ?= []).push [
          date.valueOf(),
          0
        ]

    series = {}
    period = reportHelpers.dateTimeUnitsToMomentFormat(@model.get('OPTIONS.groupingByPeriod') or 'day')
    prevDate = null
    isChangeYear = false

    _.each(@data, (item) ->
      date = moment.utc(item.name).local().startOf(period)

      # Заполняем промежутки в датах по переиоду
      (prevDate or prevDate = date.clone())

      # Вычисляем, присутствует ли в данных, смена года
      if (date.year() isnt prevDate.year())
        isChangeYear = true

      diff = if period is 'quarters' then Math.floor(prevDate.diff(date, 'month') / 3) else prevDate.diff(date, period)
      if diff < -1
        addEmptyDate(prevDate.add(1, period))
        if diff < -2
          addEmptyDate(date.clone().add(-1, period))
      prevDate = date.clone()

      # конвертация данных
      _.each(item.value, (value, name) ->
        (series[name] ?= []).push [
          date.valueOf(),
          +value.value
        ]
      )
    )

    series = _.map(series, (value, name) ->
      res =
        name: name
        color: BAR_COLORS[name]
        data: value

      if name is 'All'
        res.dashStyle = 'Dash'

      res
    )

    series = _.sortBy(series, (item) ->
      VIOLATION_LEVEL.indexOf(item.name)
    )

    if @data.length is 1
      options.plotOptions.line?.marker.enabled = true

    options.series = series
    options.xAxis.groupingByPeriod = period
    options.xAxis.isChangeYear = isChangeYear

    options

  # TODO: think about common place for such methods (as mixX/maxY/defaultX/...)
  defaultX: config.max.x
