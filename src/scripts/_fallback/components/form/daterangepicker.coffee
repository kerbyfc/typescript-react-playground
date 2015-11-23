"use strict"

helpers     = require "common/helpers.coffee"
formHelpers = require "components/form/helpers.coffee"
formatDate  = 'YYYY-MM-DD 00:00:00'

InputFormComponent = require "components/form/input.coffee"

module.exports = class DateRangePickerFormComponent extends InputFormComponent

  jquery: 'daterangepicker'

  defaults: ->
    data =
      showDropdowns : true
      opens  : @$el.data('position') or 'left'
      locale : App.t 'daterangepicker', returnObjectTrees: true
      format : 'L'

    startDate = @ui.startDate.val()
    endDate   = @ui.endDate.val()
    interval  = @ui.interval.val()

    start = moment(startDate, formatDate).format 'L' if startDate
    end   = moment(endDate, formatDate).format 'L' if endDate

    switch interval
      when 'from'
        data.startDate = start
        data.singleDatePicker = true
      when 'to'
        data.startDate = end
        data.singleDatePicker = true
      when 'range'
        data.startDate = start
        data.endDate = end

    data

  events: ->
    'apply.daterangepicker': _.bind @onApply, @

  ui: ->
    data = @$el.data()

    startDate : formHelpers.getFormElByName data.startName, @container
    endDate   : formHelpers.getFormElByName data.endName, @container
    interval  : formHelpers.getFormEl "[data-form-ui=#{data.formTarget}]", @container

  onApply: (e) ->
    daterangepicker = @$el.data 'daterangepicker'
    interval        = @ui.interval.val()

    daterangepicker.startDate.format formatDate
    daterangepicker.endDate.format formatDate

    switch interval
      when 'from'
        @ui.startDate
        .val daterangepicker.startDate.format formatDate
        .trigger 'change'
      when 'to'
        @ui.endDate
        .val daterangepicker.startDate.format formatDate
        .trigger 'change'
      when 'range'
        @ui.startDate
        .val daterangepicker.startDate.format formatDate
        .trigger 'change'

        @ui.endDate
        .val daterangepicker.endDate.format formatDate
        .trigger 'change'

  _removeDateRangePicker: ->
    if $daterangepicker = @$el.data 'daterangepicker'
      $daterangepicker.element.off()
      $daterangepicker.container.remove()
      $daterangepicker.element.removeData $daterangepicker.type

  onDestroy: ->
    @_removeDateRangePicker()

  setJquery: ->
    startDate = @ui.startDate.val()
    endDate   = @ui.endDate.val()
    interval  = @ui.interval.val()

    startDate = moment(startDate, formatDate).format 'L' if startDate
    endDate   = moment(endDate, formatDate).format 'L' if endDate

    @_removeDateRangePicker()
    switch interval
      when 'from'
        date = startDate
      when 'to'
        date = endDate
      when 'range'
        date = "#{startDate} - #{endDate}"
      else
        @$el.parent().hide()
        return

    super
    @$el.val date
    @$el.parent().show()

  _updateInterval: (e) =>
    $el       = $ e.currentTarget
    interval  = $el.val()

    switch interval
      when 'from'
        @ui.startDate.val moment().startOf('day').format formatDate
        @ui.endDate.val ''
      when 'to'
        @ui.startDate.val ''
        @ui.endDate.val moment().startOf('day').format formatDate
      when 'range'
        @ui.startDate.val moment().startOf('day').format formatDate
        @ui.endDate.val moment().endOf('day').format formatDate
      else
        @ui.startDate.val ''
        @ui.endDate.val ''

    @setJquery()

  constructor: ->
    @locale = App.t 'dashboards.widgets', returnObjectTrees: true

    super

    startDate = @ui.startDate.val()
    endDate   = @ui.endDate.val()

    unless @ui.interval.attr('name')
      if startDate
        if endDate
          interval = 'range'
        else
          interval = 'from'
      else if endDate
        interval = 'to'
      else
        interval ?= 'none'

      @ui.interval.val interval

    @setJquery()

    @ui.interval.on 'change', @_updateInterval
