"use strict"

storage = require "local-storage"

App.Behaviors.Common ?= {}

###*
 * Behavior to prevent data loss while navigation, it should be invoked
 * with browser history state changes
 *
 * @note all passed options should be passed to ConfirmDialog view
 * @note you should manually destroy view in #accept & #omit methods
 *
 * @example primary usage
 *
 *   class ProtectedItemView extends Marionette.ItemView
 *
 *    ...
 *
 *    behaviors:
 *      Guardian:
 *        title: "Warning"
 *        content: "Data wasn't saved. Are you sure ...?"
 *
 *        # Specify the url `scope` to determine situations
 *        # to do all proper checks with guardian
 *        #
 *        urlMatcher: ->
 *          "/item/#{this.model.id}"
 *
 *        # do things if urlMatcher was changed
 *        # you can prevent confirmatino by returning false
 *        #
 *        needConfirmation: (urlPath) ->
 *          this.navigateAfterConfirm = urlPath
 *          console.log "allow routing"
 *          return false
 *
 *        omit: (urlPath) ->
 *          console.log "data wasn't modified"
 *          this.destroy()
 *
 *        reject: ->
 *          console.log "data was modified,
 *            but view close was rejected by user"
 *
 *        accept: ->
 *          console.log "data was modified,
 *            and user confirmed view close"
 *          this.model.rollback()
 *          App.vent.trigger "nav", this.navigateAfterConfirm
 *
 *        always: ->
 *
 *    ...
 *
###
module.exports = class App.Behaviors.Common.Guardian extends Marionette.Behavior

  ui:
    inputs : "input, textarea, select"
    name   : "[name='DISPLAY_NAME']"

  events:
    "change @ui.inputs" : "_changed"
    "keyup @ui.inputs"  : "_changed"

  modelEvents:
    "change"         : "guard"
    "rollback"       : "cleanup"
    "sync"           : "cleanup"
    "guardian:guard" : "guard"

  ###*
   * Protected options (confrmCallbacks), that shouldn't been computed
   * for Confirm dialog constructor
   * @type {Array}
  ###
  confrmCallbacks: [
    "accept"
    "reject"
    "always"
  ]

  ###*
   * Params to be passed to confirm
   * @type {Array}
  ###
  confirmParams: [
    "title"
    "content"
  ]

  ###*
   * Default behavior options
   * @note All functions will be called (by _.result) in view scope!
   * @type {Object}
  ###
  defaults:

    ###*
     * Sign to determine if view should be protected instantly
     * @property {Boolean} initial
    ###
    initial: false

    ###*
     * Best place to store route to navigate to on accept
     * @param {String} fragment - url
     * @param {Boolean} match - route matched to subviews
    ###
    attendNavigation: (fragment, match) -> null

    ###*
     * Computed property to examine guardian necessity while route changes
     * @property {String|RegEx|Function} urlMatcher
    ###
    urlMatcher: false

    ###*
     * Confirmation dialog title
     * @property {String|jQuery|Function} title
    ###
    title: ->
      App.t "global.edit"

    ###*
     * Confirmation dialog content
     * @property {String|jQuery|Function} content
    ###
    content: ->
      "#{App.t 'global.cancel_success'}?"

    ###*
     * Make unique cache key with entity class name and it's id
     * (used as key in local storage)
     * @property {String|Function} key
    ###
    key: ->
      entity = @model.constructor.name.replace /[A-Z]/g, (letter) ->
        ":" + letter.toLowerCase()
      "#{entity.slice 1}:#{@model.id}"

    ###*
     * Do things if urlMatcher was changed
     * @property {Null|Function} needConfirmation confirmation needfull(less)
     * @note you can prevent confirmation by returning false (omit will not be invoked)
    ###
    needConfirmation: null

    ###*
     * Callback to be invoked if guardian logic wasn't affected
     * @function
    ###
    omit: -> null

    ###*
     * Do things anyway after confirmation (unless omit)
     * @function
    ###
    always: -> null

    ###*
     * Confirmation acceptance callback
     * @function
     * @note will be wrapped by guardian
     * @see #approveNavigation
    ###
    accept: -> null

    ###*
     * Confirmation rejection callback
     * @function
    ###
    reject: -> null

    ###*
     * Setter
     * @param  {Backbone.Model} model - model to backup
     * @return {Object} data to save
    ###
    backup: (model) ->
      model.toJSON()

    ###*
     * Modify data before restore model attributes
     * @param  {Object} data
    ###
    restore: (model, data) ->
      model.set data

  initialize: ->
    # check view takes the model
    unless @view.model ?= @view.options.model
      throw new Error "Guardian cant find `model` in view or view options"

    # Form behavior triggers this event on inputs change
    @listenTo @view , "form:changed"     , @guard
    @listenTo @view , "guardian:guard"   , @guard
    @listenTo @view , "guardian:cleanup" , @cleanup

    key = @_invoke "key"

    # restore model state from cache if it exists
    # this action will activate data loss protection
    if cache = storage key
      @_invoke "restore", @view.model, cache
      @log ":restore", key, cache, @view.model

    else
      if @_invoke "initial"
        @guard save: false

  ###*
   * Cleanup with behavior (or view) destruction
  ###
  destroy: ->
    @cleanup()
    super

  ###########################################################################
  # PRIVATE

  ###*
   * Compute option value by key
   * @note computing is in view scope!
   * @param  {String} key - option key
   * @param  {Array} args... arguments
   * @return {Any}
  ###
  _invoke: (key, args...) ->
    result = if opt = @options[key]
      if _.isFunction opt
        opt.apply @view, args
      else
        opt
    else
      null
    @log ":invoke", key,
      args   : args
      result : result
    result

  ###*
   * Handle inputs changes
   * @param {Event} e
  ###
  _changed: (e) =>
    @view.model.set @view.serialize(), silent: true

  ###########################################################################
  # PUBLIC

  ###*
   * Patch view with method to be invoked on navigation
   * (use view as facade)
  ###
  override: =>
    @originCond ?= @view.approveNavigation or -> true
    @view.approveNavigation = @approveNavigation

  ###*
   * Mark model as protected and cache its data
   * @param {Object} options
   * @option options {Boolean} backup - save to LS
  ###
  guard: (options = {}) =>
    @override()

    unless options.backup is false
      # cache data
      key  = @_invoke "key"
      data = @_invoke "backup", @view.model
      storage key, data
      @log ":guard", key, data, @view.model

    # register guardian
    unless @view.model.guardian
      @view.model.guardian = @
      @view.trigger "guardian:activate"

  ###*
   * Replacement of proper view method
   * if view model data needs to be protected
   * it will compute options and instantiate
   * confirm dialog with them
   * @return {Boolean} destroy decision
  ###
  approveNavigation: =>
    fragment = Backbone.history.fragment

    # check if url change was in acceptable scope
    matcher = @_invoke "urlMatcher", fragment

    match = switch $.type matcher
      when "boolean"
        matcher
      when "string", "regex"
        fragment.match matcher
      else
        false

    @_invoke "attendNavigation", fragment, match

    # needConfirmation hook can cancel confirmation by returning false
    isConfirmationNeeded = _.isFunction(@options.needConfirmation) and
        @_invoke("needConfirmation", fragment, match) is false

    if match and not isConfirmationNeeded
      # permit routing
      @log ":permit:navigation", @_invoke("key"), fragment, matcher
      return true

    # check if model is protected by guardian
    if @view.model?.guardian is @

      # compute options
      opts = _.reduce @options, (acc, opt, key) =>
        if key in @confrmCallbacks
          acc[key] = opt.bind(@view)
        else if key in @confirmParams
          acc[key] = @_invoke key
        acc
      , {}

      # show confirmation dialog
      App.Helpers.confirm _.extend {}, opts,
        accept: =>
          @cleanup()

          # apply buisness logic
          @_invoke "accept", arguments...

      # prevent
      @log ":prevent:navigation", fragment
      false

    else
      @cleanup()

      # apply buisness logic
      @_invoke "omit"

      # permit routing
      @log ":permit:navigation", fragment
      true

  ###*
   * Revert view destroy condition, cleanup model cache
   * and stop model protection
  ###
  cleanup: =>
    # cleanup view
    @view.approveNavigation = @originCond
    delete @originCond

    # clean cache
    storage.remove @_invoke "key"
    @log ":cleanup"

    # remove guardian
    if @view.model?.guardian
      delete @view.model.guardian
      @view.trigger "guardian:deactivate"
