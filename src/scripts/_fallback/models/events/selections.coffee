"use strict"

require "backbone.paginator"
require "common/backbone-nested.coffee"

helpers = require "common/helpers.coffee"

# FIXME: report helpers in events view? gloom :(
reportHelpers = require "helpers/report_helpers.coffee"
formatDate    = 'YYYY-MM-DD 00:00:00'

exports.TreeNode = class TreeNode extends App.Common.BackboneNested

  type: 'query'

  validators:
    file_size: (value) ->
      errors = {}

      if value is null
        errors["file_size[start]"] = App.t 'events.conditions.file_size_empty_validation_error'
        errors["file_size[end]"] = App.t 'events.conditions.file_size_empty_validation_error'
        return errors

      if _.isArray(value)
        if value[0] < 0
          errors["file_size[start]"] = App.t 'events.conditions.file_size_negative_validation_error'

        if value[1] < 0
          errors["file_size[end]"] = App.t 'events.conditions.file_size_negative_validation_error'

        if String(value[0]).length > 20
          errors["file_size[start]"] = App.t 'events.conditions.file_size_bigest_validation_error'

        if String(value[1]).length > 20
          errors["file_size[end]"] = App.t 'events.conditions.file_size_bigest_validation_error'

        if not _.isEmpty(errors) then return errors

        if value[0] isnt null and value[1] isnt null and value[0] > value[1]
          errors["file_size[end]"] = App.t 'events.conditions.file_size_end_less_validation_error'
          return errors

        if value[0] isnt null and value[0] isnt Number(value[0]) or value[0] % 1 isnt 0
          errors["file_size[start]"] = App.t 'events.conditions.file_size_not_number_validation_error'

        if value[1] isnt null and value[1] isnt Number(value[1]) or value[1] % 1 isnt 0
          errors["file_size[end]"] = App.t 'events.conditions.file_size_not_number_validation_error'

        if not _.isEmpty(errors) then return errors

    text: (value) ->
      if value.DATA is ''
        errors = {}
        errors["text[value]"] = App.t 'events.conditions.text_empty_validation_error'
        return errors

    file_name: (value) ->
      if value is null or (value.length is 1 and value[0] is '')
        errors = {}
        errors["file_name[value]"] = App.t 'events.conditions.file_name_empty_validation_error'
        return errors

    destination_path: (value) ->
      if value is null or (value.length is 1 and value[0] is '')
        errors = {}
        errors["destination_path[value]"] = App.t 'events.conditions.destination_path_empty_validation_error'
        return errors

    object_id: (value) ->
      errors = null

      if value is null or (value.length is 1 and value[0] is '')
        errors = {}
        errors["object_id[value]"] = App.t 'events.conditions.object_id_empty_validation_error'
        return errors

      for val in value
        if not /^\d+$/.test(val)
          errors = {}
          errors["object_id[value]"] = App.t 'events.conditions.object_id_value_validation_error'

          return errors

  isValid: (mode) ->
    value = super

    if @children
      for child in @children.models
        val = child.isValid()
        value = value and val

    value

  validate: ->
    if @has 'category'
      category  = @get 'category'
      value     = @get('value')

      if category is 'object_header'
        category = value.name
        value = value.value

      return @validators[category]?(value) or false

  initialize: ->
    if @hasChildren()
      @children = @nestCollection('children', new TreeNodeCollection(@get('children')))

  _getFactor: (data) ->
    switch data
      when 'KB'
        1024
      when 'MB'
        1024 * 1024
      when 'GB'
        1024 * 1024 * 1024
      else
        1

  rebuildCondition: (data) ->
    d = []

    _.each data, (value, key) =>
      return if not value
      return if value.value is null or value.value is ""

      model_data = @createModelData(key, value)

      if model_data
        d.push new @children.model model_data
    d

  resetCondition: (data) ->
    @children.reset @rebuildCondition data

    # to use few treeNode events for one handler
    @trigger "rebuild", data, @children

  createModelData: (key, value) ->
    @log ":createModelData", key, value

    switch key
      when 'object_id'
        val = value.value.replace(/[\s,]+/g, ',').split(',')

        return {
          category    : key
          value       : val
          is_negative : value.mode
        }

      when 'file_size'
        if value.start or value.end
          min_factor = @_getFactor(value.ATTACH_SIZE_MIN_TYPE)
          max_factor = @_getFactor(value.ATTACH_SIZE_MAX_TYPE)

          if value.start
            min_value = value.start * min_factor
          else
            min_value = null

          if value.end
            max_value = value.end * max_factor
          else
            max_value = null

          return {
            category: key
            value: [min_value, max_value]
            size: [value.ATTACH_SIZE_MIN_TYPE, value.ATTACH_SIZE_MAX_TYPE]
          }

      when 'workstation_type'
        return {
          category: 'object_header'
          value:
            name: key
            type: 'enum'
            operation: 'in'
            value: value
        }

      when 'task_name'
        return {
          category: 'object_header'
          value:
            name: key
            type: 'string'
            operation: 'like'
            value: value
        }

      when 'create_date', 'modify_date', 'task_run_date'
        return if value.start_date is "" and value.end_date is ""

        start = if value.start_date then moment(value.start_date, formatDate).utc().unix() else null
        end = if value.end_date then moment(value.end_date, formatDate).utc().unix() else null

        return {
          category: 'object_header'
          value:
            name: key
            type: 'date'
            operation: 'between'
            value: [start, end]
        }

      when 'text'
        return {
          category: key
          value:
            DATA: value.value
            morphology: if value.morphology? then (value.morphology is 1) else true
            mode: if value.raw then 'raw' else (value.search_mode or 'all')
            scope: value.scope or 'object'
          is_negative : value.mode
        }

      when 'destination_path'
        return {
          category: key
          value: value.value.split(',')
        }

      when 'file_name'
        return {
          category: key
          value: _.map value.value.split(','), _.trim
          is_negative : value.mode
        }

      when 'destination_type'
        return {
          category: 'object_header'
          value:
            name      : key
            type      : 'enum'
            operation : 'in'
            value     : value
        }

      when 'user_decision', 'violation_level', 'rule_group_type', 'verdict', 'object_type_code', 'service_code', 'protocol'
        return {
          category: key
          value: value
        }

      when 'senders', 'recipients', 'workstations', 'persons'
        val = _.map value.value, (item) ->
          contacts = App.request('bookworm', 'contact').pluck('mnemo')
          contacts = _.union contacts, ['ip', 'dns']

          if item.TYPE in contacts
            if item.TYPE is 'dns' then item.TYPE = 'dnshostname'

            return {
              TYPE    : item.TYPE
              KEY     : item.TYPE
              DATA    : $.trim item.ID
              NAME    : $.trim item.NAME
            }
          else
            return {
              TYPE: item.TYPE
              DATA: item.ID
              NAME: item.NAME
            }

        if key isnt 'persons'
          {
            category  : key
            value   : val
            is_negative : value.mode
          }

        else
          # HACK: Вставляем ноду дерева для предствления сущности Персоны
          new TreeNode
            link_operator: 'or'
            children: _.map ['senders', 'recipients'], (objectType) ->
              {
                category: objectType
                value: val
                is_negative: value.mode
              }

      when 'resources'
        val = _.map value.value, (item) ->
          if item.TYPE is 'url_with_masks'
            {
              TYPE: 'url'
              DATA: "*#{item.ID}"
              NAME: item.NAME
            }
          else
            {
              TYPE: item.TYPE
              DATA: item.ID
              NAME: item.NAME
            }

        return {
          category    : key
          value       : val
          is_negative : value.mode
        }

      when 'analysis', 'documents', 'tags', 'perimeter_in', 'perimeter_out', 'policies'
        val = _.map value.value, (item) ->
          {
            TYPE: item.TYPE
            DATA: item.ID
            NAME: item.NAME
          }

        return {
          category    : key
          value       : val
          is_negative : value.mode
        }

      when 'file_format'
        val = {}

        if value.formats and value.formats isnt ''
          val['formats'] = _.map value.formats.split('||'), (item) ->
            d = item.split('::')

            return {
              TYPE: d[0]
              DATA: d[1]
              NAME: d[2]
            }

        if value.encrypted isnt 0
          val['encrypted'] = '1'

        if not _.isEmpty(val)
          return {
            category    : key
            value       : val
            is_negative : value.mode
          }

      when 'capture_date'
        value.interval = 'period' if value.interval in ['from', 'to', 'range']
        if value.interval is 'period'
          period_value = []
          if value.start_date or value.end_date
            if value.start_date
              start_time = moment(value.start_date, formatDate).utc().unix()
            else
              start_time = null

            if value.end_date
              end_time = moment(value.end_date, formatDate).utc().unix()
            else
              end_time = null

            period_value = [start_time, end_time]

          return {
            category: key
            value:
              period: period_value
              type: value.interval
          }
        else
          if value.interval.match(/days$/)
            return {
              category: key
              value:
                type: "last_days"
                days: parseInt(value.interval.replace(/^\D+/g, ''), 10)
            }

          else
            return {
              category: key
              value:
                type: value.interval
            }

  islock: (data) ->
    data = action: data if _.isString data

    super data

  hasChildren: ->
    @has('children')

  getValue: ->
    @get('value')

  isCategoryCaptureDate: ->
    @get('category') is 'capture_date'

  isUseCaptureDate: ->
    if @hasChildren()
      return @_isUseCaptureDateFromChildren()
    else if @isCategoryCaptureDate()
      if @getValue()?.type isnt 'none'
        return true
    false

  _isUseCaptureDateFromChildren: ->
    linkOperator = @get('link_operator')
    for child in @children.models
      if linkOperator is 'and'
        if child.isUseCaptureDate()
          return true
        isUse = false
      else
        if not child.isUseCaptureDate()
          return false
        isUse = true
    return isUse

  getPeriodByRunDate: (runDate = moment()) ->
    if @isUseCaptureDate()
      if @hasChildren()
        return @_getPeriodByRunDateFromChildren(runDate)
      else if @isCategoryCaptureDate()
        return reportHelpers.createPeriodByCaptureDate(@getValue(), runDate)

    startDate: null
    endDate: runDate

  _getPeriodByRunDateFromChildren: (runDate) ->
    startDate = undefined
    endDate = runDate
    linkOperator = @get('link_operator')

    for childNode in @children.models
      if childNode.isUseCaptureDate()
        childNodePeriod = childNode.getPeriodByRunDate()

        _startDate = childNodePeriod.startDate
        startDate = _startDate if startDate is undefined
        if linkOperator is 'and'
          if startDate is null or _startDate?.isAfter(startDate)
            startDate = _startDate
        else
          if _startDate is null
            startDate = _startDate
            break
          else
            if _startDate?.isBefore(startDate)
              startDate = _startDate

        _endDate = childNodePeriod.endDate
        if linkOperator is 'and'
          if _endDate?.isBefore(endDate)
            endDate = _endDate
        else
          if _endDate?.isAfter(endDate)
            endDate = _endDate

    startDate: startDate
    endDate: endDate

  getCommonCaptureDate: ->
    if @isUseCaptureDate()
      if @hasChildren()
        return @_getCommonCaptureDateFromChildren()
      else if @isCategoryCaptureDate()
        return @getValue()
    null

  _getCommonCaptureDateFromChildren: ->
    resCaptureDate = null
    for child in @children.models
      if _childCaptureDate = child.getCommonCaptureDate()
        if resCaptureDate isnt null
          return null
        resCaptureDate = _childCaptureDate
    return resCaptureDate

class TreeNodeCollection extends Backbone.Collection
  model: exports.TreeNode

exports.model = class Selection extends App.Common.ValidationModel

  STATES:
    executing : EXECUTING = 0
    completed : COMPLETED = 1
    error     : ERROR     = 2
    addle     : ADDLE     = 3

  idAttribute: "QUERY_ID"

  type: 'query'

  displayAttribute: "DISPLAY_NAME"

  urlRoot: "#{App.Config.server}/api/selection"

  url: (action = "") ->
    @urlRoot + (@id and "/#{@id}" or "") + "#{action}" + "?with=status"

  defaults:
    DISPLAY_NAME            : ""
    QUERY_ID                : null
    FOLDER_ID               : null
    QUERY_TYPE              : null
    QUERY                   : null
    USER_ID                 : null
    IS_PERSONAL             : 1
    IS_AUTO_UPDATE_ENABLED  : 0
    AUTO_UPDATE_INTERVAL    : 0

  query_types: ['query', 'selection', 'report']

  initialize: (options = {}) ->
    unless @id or options.QUERY
      data = options.condition or {link_operator: 'and', children: []}

      # По умолчанию создаем дефолтный QUERY
      @set 'QUERY',
        mode: options?.mode or 'lite'
        data: data
        columns: []
        sort:
          CAPTURE_DATE: "desc"

  toJSON: (options = {}) ->
    data = super

    data.DISPLAY_NAME = _.escape data.DISPLAY_NAME
    if options.withoutWidgets
      delete data.widgets

    if options.withoutStatus
      delete data.status

    data

  ###*
   * Check options for `forceType` key and
   * change QUERY_TYPE after parsing
   * @param  {Object} attrs
   * @param  {Object} options = {}
   * @return {Object} parsed attributes
  ###
  parse: (attrs, options = {}) ->
    data = super

    if _.isString data.QUERY
      data.QUERY = $.parseJSON data.QUERY

    if options.forceType
      data.QUERY_TYPE = options.forceType

    data

  copy: (newName, model) ->
    data = @toJSON()
    data = _.omit data, [
      'QUERY_ID',
      'CHANGE_DATE'
      'CREATE_DATE'
      'HASH'
      'user'
      'status'
    ]

    if newName
      data.DISPLAY_NAME = newName
    else
      data.DISPLAY_NAME = App.Helpers.generateCopyName data.DISPLAY_NAME, (name) =>
        _.any @collection.models, (query) ->
          name is query.get "DISPLAY_NAME"

    if model
      model.set @parse data
      model
    else
      new Selection @parse data

  ###*
   * Reject conditions by category.
   * @note If conditions are passed as second argument
   *   and they are not actual model conditions (ref equality),
   *   method shouldn't set model QUERY attribute,
   *   but should only return mutated object.
   * @param {Array} categories - categories to reject
   * @param {Object|Array} conditions - query object of conditions array
   * @return {Object} mutated conditions object
  ###
  rejectConditions: (categories, conditions = @get("QUERY"), depth = 1) ->
    shouldModify = depth is 1 and conditions is @get("QUERY")
    conditions   = helpers.cloneDeep(conditions)

    # few data structures support (for convinience)
    conditions = conditions.data or conditions
    children   = conditions.children or conditions

    if _.isArray children
      for condition, index in children
        if condition.category in categories
          delete children[index]
        else
          if childs = condition.children
            condition.children = @rejectConditions categories, childs, depth+1

      children = _.compact children

      # modify model only if data structure was proper
      if shouldModify
        query = @get "QUERY"
        query.data.children = children
        @set "QUERY", query

    children

  saveCondition: (data = {}, options = {}) ->

    $deferred = $.Deferred()

    data = _.extend {}, data,
      QUERY_TYPE   : data.QUERY_TYPE or 'query'
      USER_ID      : options.chown or App.Session.currentUser().get('USER_ID')

    data.QUERY = JSON.stringify @get('QUERY')

    @save data, _.merge options,
      success: (model, response, options) ->
        $deferred.resolve(model, response, options)
      error: (model, response, options) ->
        $deferred.reject(model, response, options)

    $deferred.promise()

  createCondition: (data) ->
    model = new TreeNode
      link_operator: 'and'
      children: []

    _.each data, (value, key) ->
      return if not value
      return if value.value is null or value.value is ""

      model_data = model.createModelData(key, value)

      if model_data
        model.children.add new model.children.model model_data

    return model

  execute: (opts) ->
    url = @url '/execute'

    options =
      url  : url
      type : 'POST'

    _.extend options, opts if opts

    (@sync or Backbone.sync).call(@, null, @, options)

  validation:
    DISPLAY_NAME: [
      {
        required : true
        msg      : App.t 'events.conditions.selection_required_validation_error'
      }
    ]
    'QUERY': (value) ->
      val = $.parseJSON value
      value = new TreeNode val.data
      return true unless value.isValid()

  islock: (data) ->
    data = action: data if _.isString data

    super data

  getMode: ->
    @get('QUERY').mode or null

  setMode: (mode) ->
    prevMode = @getMode()
    if prevMode isnt mode
      @get('QUERY').mode = mode
      @trigger "change:query:mode", mode

  getStatus: ->
    @get('status')?.STATUS

  isCompleted: ->
    @getStatus() is COMPLETED

  isAddle: ->
    @getStatus() is ADDLE

exports.collection = class Selection extends Backbone.Collection

  model: exports.model

  defaultParams: ->
    sort: @sortRule or CHANGE_DATE: 'desc'

  url: ->
    url = "#{App.Config.server}/api/selection?"
    params = {}

    if not @options.overrideParams
      _.extend params, @defaultParams()

    _.extend params, @options.params
    url += $.param params

    if @filter
      url = url + "&" + $.param(@filter)

    url

  initialize: (models = [], options = {}) ->
    @options = options
