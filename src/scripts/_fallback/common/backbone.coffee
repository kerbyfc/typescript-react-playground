require "i18next"
NProgress = require "nprogress"
helpers   = require "common/helpers.coffee"

"use strict"
$.xhrPool = []
$.xhrPool.abortAll = ->
  $(@).each (idx, jqXHR) ->
    unless jqXHR.unabortable then jqXHR.abort()

  $.xhrPool.length = 0

incrementor_id = 0

showGlobalXhrProblem = _.throttle (errorCode) ->
  App.Notifier.showError App.t errorCode
, 1000, leading: false

$.ajaxSetup
  beforeSend: (jqXHR) ->
    $.xhrPool.push(jqXHR)

    return if @disableNProgress

    NProgress.set 0.1
    clearInterval incrementor_id

    incrementor_id = setInterval ->
      NProgress.inc()
    ,
      1000

  complete: (jqXHR) ->
    index = $.xhrPool.indexOf(jqXHR)
    if index > -1
      $.xhrPool.splice(index, 1)

    if jqXHR.responseText?.match(/^[\w\_]+$/)?
      errorCode = "global.#{jqXHR.responseText}"
      if $.i18n.exists errorCode
        showGlobalXhrProblem errorCode

    return if @disableNProgress

    clearInterval incrementor_id
    NProgress.done()

$.ajaxPrefilter (options, originalOptions, jqXHR) ->
  jqXHR.unabortable = options.headers?.unabortable
  return

Backbone.Model::nameAttribute = "DISPLAY_NAME"

Backbone.Model::getName = -> @get @nameAttribute

Backbone.Model::can = -> not @islock arguments...

Backbone.Model::islock = (o = {}) ->
  o = action: o if _.isString o

  type = o.type
  type ?= @type

  o.type = type

  helpers.islock arguments...

class Backbone.Model extends Backbone.Model

  ###*
   * Alias to $.i18n
   * @type {Function}
  ###
  t: (key, options = {}) ->
    if options.context is 'label'
      defaultValue = App.t "global.#{key}", options
      return App.t "entry.#{@type or options.type}.#{key}",
        _.extend options, defaultValue: defaultValue

    if options.context is 'title'
      return App.t "select_dialog.#{key or @type}"

    if options.context is 'error'
      defaultValue = App.t "form.error.#{key}", options
      return App.t "entry.#{@type or options.type}.#{options.name}_#{key}",
        _.extend options, defaultValue: defaultValue

    App.t key, options

  ###*
   * Backbone.Undo is redundant, there is the most simple
   * way to backup and rollback model's data
  ###
  constructor: ->
    # clone to avoid changing @defaults by
    # changing of nested attributes
    @__backup = null
    unless _.isFunction @defaults
      @defaults = helpers.cloneDeep @defaults

    @on "change", @backup
    @__fetching = false

    @on "sync",       => @__backup   = null
    @on "request",    => @__fetching = true
    @on "sync error", => @__fetching = false

    super

  wrapError: (model, options) ->
    super
    error = options.error
    options.error = =>
      @__fetching = false
      error arguments...

  isFetching: ->
    @__fetching

  ###*
   * Backup model data once
   * @see #constructor
   * @return {Object} backup
  ###
  backup: (model) =>
    # If called without params, than current attrs
    if model isnt @
      @__backup = helpers.cloneDeep @attributes

    else
      if not @__backup?
        # when first "change" event fires,
        # previous data is origin
        attrs = @previousAttributes()
        if not _.size attrs
          attrs = @attributes

        @__backup = helpers.cloneDeep @attributes

    @__backup

  ###*
   * Restore backuped model data
   * @see #constructor
   * @param  {Object} options = {} - set options
   * @return {Object} backup
  ###
  rollback: (options = {}) =>
    bac = null
    if @__backup?
      bac = helpers.cloneDeep @__backup
      @set bac, options
      @trigger "rollback", @, bac
    bac

  ###*
   * Check if one or few attributes were changed by last set.
   * Unlike the original, this method can find changed keys by regex.
   * @example
   *  model.hasChanged /_(DATE|ID)/
   * @override
   * @param {String|Null|RegExp} attr - attr to search
   * @return {Boolean} check truthfulness
  ###
  hasChanged: (attr) ->
    if attr instanceof RegExp
      attr.test(_.keys(@changed).join())
    else
      super

  ###*
   * Check if attribute or whole model attributes set
   * was changed since last sync with server
   * @param {String} attr [optional] attr to check
   * @return {Object|Any} difference object or old attr value
   * TODO: should return only true, separate _.reduce to another method
  ###
  isDirty: (attr) ->
    if attr
      if not @__backup or helpers.isEqual @__backup[attr], @get attr
        false
      else
        true
    else
      if not @__backup or helpers.isEqual @attributes, @__backup
        false
      else
        # return difference object
        _.reduce @__backup, (acc, val, key) =>
          if not helpers.isEqual @attributes[key], val
            acc[key] = val
          acc
        , {}

  ###*
   * Use deep cloning instead of simple
   * TODO: 'To use' or 'Not to use' - that's the question
   *   Is it correct to store models and collections
   *   inside model attributes?
   * @return {Object} cloned attributes
  ###
  toJSON: ->
    helpers.cloneDeep @attributes

  parse: (res) ->
    @__fetching = false
    res.data or res

  log: helpers.createLogger "model"

  # TODO: в дальнейшем впилить проверку прав (islock) для всех моделей
  # и реализовать эту проверку для всех операций, до ее реализации на бекенде
  # sync: (action) ->
  #   islock = @islock action: action
  #   if islock
  #     App.Notifier.showError
  #       title : App.t "select_dialog.#{@type}"
  #       text  : islock.message
  #       hide  : true
  #     return

  #   super

  systemAttribute: "IS_SYSTEM"

  isSystem: -> +@get(@systemAttribute) is 1

  enabledAttribute: "ENABLED"

  isEnabled: -> +@get(@enabledAttribute) is 1

  deserialize: -> @toJSON arguments...


Backbone.Collection::can = -> not @islock arguments...

Backbone.Collection::islock = (o = {}, original) ->
  o = action: o if _.isString o
  action = o.action

  type = o.type
  type ?= @model::type

  o.type = type unless o.module

  islock = helpers.islock o
  return islock if islock

  islock =
    state : 1
    mode  : 'disabled'

  selected = o.selected or @getSelectedModels?() or []
  selected = [ selected ] if not _.isArray selected

  toolbar = _.result @, 'toolbar'

  action = if original then original.action or original else action

  if method = toolbar?[action]
    # TODO: в дальнейшем переделать
    val = method.call @, selected
    if val
      if val.length
        islock.message = val[1]
        islock.state   = val[0]
      else
        islock.state = 1

      return islock
  else
    # TODO: впилить стандартные проверки из требований
    switch action
      when 'edit', 'show'
        return islock if selected.length isnt 1
      when 'delete', 'policy'
        return islock unless selected.length
      when 'activate', 'deactivate'
        return false if selected.length > 1
      when 'export', 'import'
        if App.Configuration.isEdited()
          return _.extend islock,
            state   : 2
            message : @model::t 'configuration_edit', context : 'error'

  false

class Backbone.Collection extends Backbone.Collection

  parse : (resp) ->
    @total_count = resp.totalCount
    resp.data or resp

  # TODO: прочесать коллекции и прибить @t
  t: App.t

  log: helpers.createLogger "collection"

  fetchOne: (id, o, success) ->
    unless o.refetch
      result = @get id
      if typeof result isnt 'undefined'
        success?.apply @, [result]
        return result

    where = {}
    where[@model::idAttribute] = id
    model = new @model where, collection: @

    model.fetch _.extend o, success: (model) =>
      if success
        @add model, o
        success.apply @, [model]
    model

  save : (data, options = {}) ->
    options.contentType ?= "application/json"

    if data instanceof Backbone.Collection
      options.data = JSON.stringify data.toJSON()

    if _.isArray data
      options.data = JSON.stringify data

    response = Backbone.sync(
      "update"
      @
      _.omit(
        options

        "add"
        "remove"
        "merge"
        "reset"

        "error"
        "success"
      )
    )

    response.done(
      (resp) =>
        if options.reset
          @reset resp.data
        else
          set_options = _.pick(options, "add", "remove", "merge")
          @set resp.data, set_options

        @trigger "sync", @, resp.data, options
        options.success?(@, resp.data, options)
    )

    response.fail(
      (xhr) =>
        @trigger "error", @, xhr, options
        options.error?(@, xhr, options)
    )

    response

  getLength: -> @models.length

  getTotalLength: -> @models.length

  getItem: (i) -> @models[i]
