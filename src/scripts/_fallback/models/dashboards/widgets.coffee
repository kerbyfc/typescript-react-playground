"use strict"

formatDate = 'YYYY-MM-DD 00:00:00'

###*
 * TODO: devide this model into two parts: one for dashboards renderers
 * and second for generate_report dialog
###
exports.Model = class WidgetItem extends App.Common.ValidationModel

  urlRoot: "#{App.Config.server}/api/dashboardWidget"

  idAttribute: "DASHBOARD_WIDGET_ID"

  type: 'widget'

  defaults:
    BASEOPTIONS: JSON.stringify
      periodUpdate    : ''
      default_period  : 'this_day'

    details         :  1
    details_count   :  10
    includeInReport :  1

  save: (key, value, options) ->
    if (_.isObject(key) or key is null)
      attrs = key
      options = value
    else
      attrs = {}
      attrs[key] = value

    if attrs and "BASEOPTIONS" of attrs
      @set('BASEOPTIONS', attrs.BASEOPTIONS)
      delete attrs.BASEOPTIONS

    # Сереализуем BASEOPTIONS в строку при сохранении
    if typeof @get('BASEOPTIONS') is 'object'
      @attributes.BASEOPTIONS = JSON.stringify(@.get('BASEOPTIONS'))

    return Backbone.Model.prototype.save.call @, attrs, options

  parse: (response, options) ->
    response = response.data ? response
    response.BASEOPTIONS = $.parseJSON response.BASEOPTIONS
    response

  getName: ->
    widgetName = @get('DISPLAY_NAME')
    locale = App.t 'dashboards', { returnObjectTrees: true }

    if /^<.*>$/.test(widgetName)
      widgetName = locale.widgets[widgetName] ? widgetName

    widgetName

  islock: (data) ->
    @collection.dashboard.islock arguments...

  createWidgetInterval: (isGMT = false ) =>
    baseopts = @get("BASEOPTIONS")

    if isGMT
      _start_time = moment.utc()
      _end_time = moment.utc()
    else
      _start_time = moment()
      _end_time = moment()

    switch baseopts.default_period
      when 'this_day'
        start_time  = _start_time.startOf('day')
        end_time    = _end_time.endOf('day')
      when 'last_3_days'
        start_time  = _start_time.subtract('days', 3).endOf('day')
        end_time    = _end_time.endOf('day')
      when 'last_7_days'
        start_time  = _start_time.subtract('days', 7).endOf('day')
        end_time    = _end_time.endOf('day')
      when 'this_week'
        start_time  = _start_time.startOf('week').startOf('day')
        end_time    = _end_time.endOf('week').endOf('day')
      when 'this_month'
        start_time  = _start_time.startOf('month').startOf('day')
        end_time    = _end_time.endOf('month').endOf('day')
      when 'last_30_days'
        start_time  = _start_time.subtract('days', 30).endOf('day')
        end_time    = _end_time.subtract('days', 1)
      when 'range'
        if isGMT
          start_datetime  = if baseopts.start_datetime then moment.utc(baseopts.start_datetime, formatDate) else moment.utc()
          start_time      = start_datetime.startOf('day')
          end_datetime    = if baseopts.end_datetime then moment.utc(baseopts.end_datetime, formatDate) else moment.utc()
          end_time        = end_datetime.endOf('day')
        else
          start_datetime  = if baseopts.start_datetime then moment(baseopts.start_datetime, formatDate) else moment()
          start_time      = start_datetime.startOf('day')
          end_datetime    = if baseopts.end_datetime then moment(baseopts.end_datetime, formatDate) else moment()
          end_time        = end_datetime.endOf('day')

    return [start_time, end_time]

  validation:
    details_count: [
      fn: (value) ->

        if  not value.toString().match(///^(0|([1-9]\d*))$///)
          App.t 'form.error.natural_number_or_zero'

    ]

  validate: (data) ->
    error = super
    if (@get('includeInReport') is 1) and (@get('details') is 1)
      error
    null


exports.Collection = class Widgets extends Backbone.Collection

  url: "#{App.Config.server}/api/dashboardWidget"

  model: exports.Model

  comparator: (model1, model2) ->
    if model1.get('LINE') is model2.get('LINE')
      return model1.get('COL') - model2.get('COL')

    return model1.get('LINE') - model2.get('LINE')

  isValid: =>

    hasMembers = false
    isValid = true

    _.each @models, (model) ->

      if model.get('includeInReport') is 1
        hasMembers = true
        if (model.get('details') is 1) and (model.isValid() is not true)
          isValid = false

    isValid and hasMembers
