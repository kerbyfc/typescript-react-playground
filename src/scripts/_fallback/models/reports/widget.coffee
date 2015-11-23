"use strict"

LinearModel   = require "backbone.linear"
Blender       = require "common/blender.coffee"
Selection     = require "models/events/selections.coffee"

reportHelpers = require "helpers/report_helpers.coffee"

# Create virtual class with validation and nested attributes
ValidationLinearModel = App.Helpers.virtual_class(
  LinearModel
  App.Common.ValidationModel
)

###*
 * Virtual proxy methods to check model state consistency with blender
 * @method #isConsistent(object)
 * @method #isntConsistent(object)
 * @method #blend(object)
###
exports.model = class ReportWidgetModel extends ValidationLinearModel

  ###*
   * Id attribute name
   * @type {String}
  ###
  idAttribute: "QUERY_REPORT_WIDGET_ID"

  type: "report_widget"

  ###*
   * Hasn't own api methods
   * @see  ReportModel
   * @type {String}
  ###
  url: "/"

  ###*
   * Statistic types.
   * Available options for
   * WIDGET_TYPE attribute
   * @type {Array}
  ###
  types: [
    "events_type"         # Тип события
    # "category"          # Категории
    "protected_document"  # Объекты защиты
    "protected_catalog"   # Каталоги объектов защиты
    "object_to_list"      # Тематики ресурсов
    "policy"              # Политики
    "person_activity"     # Динамика активности
    "sender_receiver"     # Диалоги
    "sender"              # Отправители
    "receiver"            # Получатели
    "workstation"         # Компьютеры
    "web_resources"       # Сайты"
    "user_decision"       # Решение пользователя
  ]

  ###*
   * Available options for
   * @type {Array}
  ###
  views: [
    "bar_grouped"
    "bar_stacked"
    "pie"
    "line"
    # "column_stacked"
  ]

  ###*
   * Available options for
   * OPTIONS "groupingByPeriod" property
   * @type {Array}
  ###
  periods: [
    "minute"
    "hour"
    "day"
    "week"
    "month"
    "quarter"
    "year"
  ]

  ###*
   * Available options for
   * OPTIONS "violationLevels" property
   * @type {Object}
  ###
  violationLevels: violationLevels =
    all    : 1
    high   : 1
    medium : 1
    low    : 1
    no     : 1

  generateId: ->
    String(new Date().getTime()).slice(-5)

  ###*
   * Default attributes
   * @type {Object}
  ###
  defaults: ->
    LinearModel.flatten
      QUERY_REPORT_WIDGET_ID : @generateId()
      QUERY_REPORT_ID        : 'new'
      QUERY_ID               : null
      WIDGET_TYPE            : 'protected_document'
      WIDGET_VIEW            : 'bar_grouped'
      DISPLAY_NAME           : ""

      OPTIONS:
        groupBy          : "VIOLATION_LEVEL"
        groupingByPeriod : 'day'
        limit            : 3
        showValues       : 1
        showPercentage   : 1
        showOthersGroup  : 1
        showTotals       : 1
        violationLevels  : violationLevels

  ###*
   * Validation rules
   * @type {Object}
  ###
  validation:
    DISPLAY_NAME: [
      {
        # apply rule only for non-empty names,
        # as field is not required and value can be
        # generated
        fn: "validateName"
      }
    ]
    'OPTIONS.limit':
      fn: (value, attr) ->
        range = [1, 100]
        widgetType = @get 'WIDGET_TYPE'
        if @isConsistent(type: widgetType, option: attr) and
            (not _.isNumber(+value) or
            value < range[0] or
            value > range[1])

          $.t "reports.validation.widget.OPTIONS.limit__range", range

  ###*
   * Compute standart validation rangeLength message
   * @return {String}
  ###
  _invalidNameLengthMessage: _.memoize (min, max) ->
    replacements = [max, min, App.t "global.DISPLAY_NAME"]
    App.t("form.error.rangeLength").replace /\%s/g, ->
      replacements.pop()

  ###*
   * Validate DISPLAY_NAME only if it's not empty
   * @param  {String} value
   * @param  {String} attr name
   * @param  {Object} computedState
   * @return {String|Boolean} error message or true
  ###
  validateName: (value, attr, computedState) ->
    if $.trim value
      if value.length < 3 or value.length > 50
        return @_invalidNameLengthMessage 3, 50

  ###*
   * Rules to determine if current state is inconsistent, when
   * two or more model property values leads to a business logic collision
   * @todo Should be more compact by specifying only inconsistent rules
   * @note There are two rule groups, positive matchings would be processed first
   * @type {Object}
  ###
  stateConsistencyRules:

    consistent: [
      ///
        bar   # view
        |pie  # view
        |line # view
        |grid # option
      ///

      # most of all types supports bar and pie charts
      ///
        bar                 # view
        |pie                # view
        |events_type        # type
        |category           # type
        |protected_document # type
        |protected_catalog  # type
        |object_to_list     # type
        |policy             # type
        |sender_receiver    # type
        |sender             # type
        |receiver           # type
        |workstation        # type
        |web_resources      # type
        |user_decision      # type
      ///

      # show some options only with proper views and types
      ///
        line        # view
        |column_stacked   # view
        |person_activity  # type
        |count        # option
        |groupingByPeriod # option
      ///

      # show "all" violation level option only for line view
      ///
        line  # view
        |Levels # option
      ///

      # column view hasn't "all" option
      # FIXME use negotiation
      ///
        column_stacked         # view
        |Levels.(high|low|medium|no) # option(s)
      ///

      # show some options only for non-dynamic charts
      ///
        showValues    # option
        |bar      # view(s)
        |pie      # view
      ///

      # show persentage option only for pie chart
      ///
        pie       # view
        |showPercentage # option
      ///

      # allow groupBy for bar views
      ///
        bar    # view(s)
        |groupBy # option
      ///

      ///
        showOthersGroup     # option
        |limit              # option
        |events_type        # type
        |category           # type
        |protected_document # type
        |protected_catalog  # type
        |object_to_list     # type
        |policy             # type
        |sender_receiver    # type
        |sender             # type
        |receiver           # type
        |workstation        # type
        |web_resources      # type
      ///

    ]

    inconsistent: [
      # disable bar & pie for charts that represents dynamic
      ///
        person_activity # type
        |bar            # view
        |pie            # view
      ///

      ///
        sender_receiver # type
        |pie            # view
      ///

      # dont show limit for some types
      ///
        limit       # option
        |user_decision    # type
      ///
    ]

  ###*
   * Forced parse added
   * @param  {Object} attributes
   * @param  {Object} options
  ###
  constructor: (attributes, options = {}) ->
    if query = App.request "reports:get:query", attributes.QUERY_ID
      @query = query.copy()
    else
      @query = new Selection.model

    options.parse = true
    super attributes, options

  ###*
   * Instantiate blender
  ###
  initialize: ->
    @blender = new Blender @stateConsistencyRules
    @blender.bridge @
    @on "rollback", @onRollback

  ###*
   * Model is new also if it's id matches 5 numbers.
   * This numbers are 5 last nubmers of utc timestamp.
   * @override
   * @return {Boolean}
  ###
  isNew: ->
    id = @get @idAttribute
    String(id).match(/^\d{5}$/)? or id is "new"

  islock: (data) ->
    data = action: data if _.isString data
    data.type = "report"
    super data

  ###*
   * Mixin default values, then flatten with linear
   * @param  {Object} data - fetched data
   * @return {Object} flattened data
  ###
  parse: (data) ->
    @fetchQuery data.query

    # parse options
    if _.isString data.OPTIONS
      data.OPTIONS = JSON.parse data.OPTIONS

    # query shouldn't be in attributes
    delete data.query

    # flatten options without
    data = LinearModel.flatten _.omit data, 'query'
    data = _.defaults data, @defaults

    data

  ###*
   * If query data was passed - create a query, else get it from cache
   * If no query was found - create it and fetch data
   * @param  {Object|Number} query - query data or query id
   * @return {Backbone.Model} query model
  ###
  fetchQuery: (queryData) ->
    if _.isObject queryData
      @query.set @query.parse queryData
      @query.backup()
      App.vent.trigger "reports:register:query", @query

  ###*
   * Form model json representation
   * @param  {Object} options - transform options
   * @return {Object}
  ###
  toJSON: (options = {}) ->
    data = super

    # Cleanup is needed to save report with nested widgets
    if options.cleanup?

      [type, view] = _.values @pick ["WIDGET_TYPE", "WIDGET_VIEW"]

      data = super _.extend {}, options, unflat: true

      # remove extra options
      for option of data.OPTIONS
        # TODO terrible code
        unless  @isConsistent(view: view, option: option) or
            @isConsistent(type: type, option: option)
          delete data.OPTIONS[option]

      if @query
        # link query
        if (id = @query.get "QUERY_ID") and !!id and not options.copy
          data.QUERY_ID = id
        else
          delete data.QUERY_ID

      # remove "new" ids
      for prop in ['QUERY_REPORT_WIDGET_ID', 'QUERY_REPORT_ID']
        if not data[prop] or String(data[prop]).match(/new/)?
          delete data[prop]
          # data[prop] = null

    # reset ids while copying
    if options.copy?
      for prop in ['QUERY_REPORT_WIDGET_ID', 'QUERY_REPORT_ID']
        delete data[prop]

    if @query and not options.withoutQuery
      _.extend data, query: @query.toJSON _.defaults options,
        withoutWidgets : true
        withoutStatus  : true

      data.query.QUERY_TYPE = 'report'

      if data.query.QUERY_ID is null or options.copy?
        delete data.query.QUERY_ID

    if not data.query and options.safe
      delete data.query

    # cleanup ids, server will resolve them,
    # and return in response
    if data.query
      delete data.query.QUERY_ID
      delete data.query.HASH
      delete data.query.user

    delete data.QUERY_ID

    # HACK: remove non-uppercase props
    # TODO: find where they are adding
    if options.safe
      for obj in [data, data.query] when obj?
        for key, val of obj
          if key.match(/^[a-z]+$/)? and
          not _.isObject(val) and
          key isnt 'copy'
            delete data.query[key]

      delete data.query.status

    if options.chown
      data.USER_ID = options.chown

    if not options.withUser and data.user
      delete data.user

    data

  ###*
   * Collect flatten OPTIONS
   * @return {Object} filtered attributes
  ###
  getOptions: ->
    _.pick @attributes, _.filter @keys(), (key) -> key.match(/OPTIONS/)?

  getCondition: ->
    @condition ?= new Selection.TreeNode @query.get('QUERY').data

  captureDateToPeriod: (runDate) ->
    @getCondition().getPeriodByRunDate(runDate)

  captureDateToString: (runDate) ->
    if not condition = @getCondition()
      return ""

    if captureDate = condition.getCommonCaptureDate()
      return reportHelpers.captureDateToString(captureDate, runDate)

    period = condition.getPeriodByRunDate(runDate)
    reportHelpers.periodToString(period)

  ###*
   * When model was created as nested model for report run model,
   * then it has 'data' attribute, that contains report run results
   * @return {Array}
  ###
  getChartData: ->
    @get('data') or []

  getSelectedViolationLevels: ->
    _violationLevels = reportHelpers.VIOLATION_LEVELS.concat(['All'])
    _.filter _violationLevels, (level) =>
      @get "OPTIONS.violationLevels.#{level.toLowerCase()}"

  setWidgetType: (widgetType) ->
    chartType = @get "WIDGET_VIEW"

    if not @isConsistent(view: chartType, type: widgetType)
      @_savePresetOptions chartType
      chartType = _.find @views, (_chartType) =>
        @isConsistent
          view: _chartType
          type: widgetType
      presetOptions = @_getPresetOptions chartType

    @set _.extend
      WIDGET_TYPE: widgetType
      WIDGET_VIEW: chartType
    , presetOptions

  setChartType: (chartType) ->
    previousChartType = @get('WIDGET_VIEW')
    @_savePresetOptions previousChartType

    presetOptions = @_getPresetOptions chartType
    @set _.extend
      WIDGET_VIEW: chartType
    , presetOptions

  setGridOptions: (gridCoords) ->
    flattenedGridOptions = LinearModel.flatten(
      OPTIONS:
        grid:
          col    : gridCoords.col
          row    : gridCoords.row
          size_x : gridCoords.size_x
          size_y : gridCoords.size_y
    )
    @set flattenedGridOptions, silent: true

  getGridCoords: ->
    LinearModel.unflatten(@attributes)?.OPTIONS?.grid or {}

  _savePresetOptions: (presetName) ->
    preset = @presetOptions[presetName]
    return if not preset

    presetOptions = LinearModel.flatten preset
    savedModelOptions = _.reduce presetOptions, (modelOptions, itemValue, itemName) =>
      currentValue = @get itemName
      modelOptions[itemName] = if currentValue is undefined then itemValue else currentValue
      modelOptions
    , {}
    savedPresetOptions = @_savedPresetOptions or (@_savedPresetOptions = [])
    savedPresetOptions[presetName] = savedModelOptions

  _getPresetOptions: (presetName) ->
    preset = @_savedPresetOptions?[presetName] or @presetOptions[presetName]
    if not preset
      return {}
    LinearModel.flatten preset

  presetOptions:
    line:
      OPTIONS:
        violationLevels: violationLevels
        groupingByPeriod: 'day'

    bar_grouped:
      OPTIONS:
        limit: 3
        groupBy: "VIOLATION_LEVEL"
        showValues        : 1
        showOthersGroup   : 1

    bar_stacked:
      OPTIONS:
        limit: 7
        groupBy: "VIOLATION_LEVEL"
        showValues        : 1
        showOthersGroup   : 1

    pie:
      OPTIONS:
        limit: 5
        showValues        : 1
        showOthersGroup   : 1
        showPercentage    : 1

  clone: ->
    new ReportWidgetModel(@toJSON())

  destroy: ->
    @trigger "destroy", @, @collection

  onRollback: ->
    @query?.rollback()

exports.collection = class ReportWidgetsCollection extends Backbone.Collection

  ###*
   * Model to work with
   * @type {ReportWidgetModel}
  ###
  model: exports.model

  ###*
   * Hasn't own api methods
   * @see  ReportModel
   * @type {String}
  ###
  url: "/"

  getLast: ->
    @last()

  resolveUniqueWidgetName: (widget, newWidgetName) ->
    type = widget.get 'WIDGET_TYPE'
    widgetName = newWidgetName or widget.get('DISPLAY_NAME') or @t "reports.widget.types.#{type}"

    widgetName = App.Helpers.resolveUniqueName widgetName, (name) =>
      @any (_widget) ->
        return false if widget is _widget
        name is _widget.get 'DISPLAY_NAME'

    widget.set 'DISPLAY_NAME', widgetName, silent: true
