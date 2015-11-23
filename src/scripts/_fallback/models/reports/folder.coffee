"use strict"

helpers = require "common/helpers.coffee"
storage = require "local-storage"

Report = require "./report.coffee"
TreeCollection = require "common/tree_collection.coffee"

exports.model = class ReportFolder extends App.Common.ValidationModel

  url: ->
    "#{App.Config.server}/api/selectionFolder/#{@id or ''}"

  idAttribute       : "FOLDER_ID"
  nameAttribute     : "DISPLAY_NAME"
  parentIdAttribute : "PARENT_FOLDER_ID"

  defaults:
    FOLDER_ID        : "new"
    PARENT_FOLDER_ID : null
    DISPLAY_NAME     : ""
    FOLDER_TYPE      : "report"
    IS_PERSONAL      : 1

  ###*
   * Privilege actions prefix (scope)
   * @type {String}
  ###
  priviledgesScope: "monitoring_reports"

  isNew: ->
    id = @get @idAttribute
    not String(id).match(/^\d+$/)? or id is "new"

  constructor: (attributes, options) ->
    # create reports colleciton
    @reports = new Report.collection attributes?.reports or []
    super attributes, options

  initialize: ->
    @on "all", (event, model, collection) ->
      App.vent.trigger "reports:folder:#{event}", model, collection

  error: (errors, models, resp) ->
    if _.has(resp, "DISPLAY_NAME") and _.contains(resp.DISPLAY_NAME, "unique")
      parentToSetName = if @_parentToSet
        @collection?.get(@_parentToSet).get("DISPLAY_NAME")
      else
        ""
      return DISPLAY_NAME: [
        @t "reports.folder.#{@_parentToSet and "not_unique_name" or "exists_in_root"}",
          folder: @get "DISPLAY_NAME"
          parent: parentToSetName
      ]
    errors

  ###*
   * Update reports nested collection
   * @param  {Object} data
   * @return {Object} processed data
  ###
  parse: (data) ->
    data = super data
    _.defaultsDeep(data, @defaults)
    if data.reports
      @reports.reset data.reports, parse: true
      delete data.reports
    data

  maxNameLength: 50

  ###*
   * Validation rules
   * @type {Object}
  ###
  validation:
    DISPLAY_NAME: [
      required  : true
      rangeLength : [3, @::maxNameLength]
    ]

  ###*
   * Notify user about api action results
   * @param  {String} action
   * @param  {String} result - action status
  ###
  notify: notify = (method, action, result, data = {}) ->
    data = _.extend {}, @toJSON(), data
    App.Notifier[method]
      title : @t "reports.pnotify.folder_#{action}", data
      text  : @t "reports.pnotify.folder_#{action}_#{result}", data
      delay : data.delay or 3000

  notifySuccess : _.partial notify, "showSuccess"
  notifyError   : _.partial notify, "showError"
  notifyWarning : _.partial notify, "showWarning"
  notifyInfo    : _.partial notify, "showInfo"

  toJSON: (options = {}) ->
    id   = @id
    data = super

    if options.full
      data.reports = @reports.toJSON options

      if @collection?
        data.children = _ @collection.models
          .filter (folder) ->
            id is folder.get "PARENT_FOLDER_ID"
          .map (folder) ->
            folder.toJSON options
          .value()

      if options.safe
        delete data.children unless data.children.length
        delete data.reports unless data.reports.length

    else
      if not @isNew()
        # prevent updates with reports
        # to avoid data losing
        delete data.reports

    if options.copy
      delete data.FOLDER_ID
      delete data.PARENT_FOLDER_ID

    if options.chown
      data.USER_ID = options.chown

    data

  ###*
   * Unset "new" id for new model and rollback it on error
   * @override
   * @param  {Object} data
   * @param  {Object} options
   * @return {jQuery.Deferred} deferred object
  ###
  save: (data, options = {}) ->
    return if not @can "edit"

    if isNew = @isNew()
      # cleanup id
      @unset @idAttribute, silent: true
      if _.isObject data
        delete data[@idAttribute]

      @once "request", =>
        if isNew
          @set @idAttribute, "new", silent: true

    origin = _.pick options, "error", "success"

    personalityChanged = @isDirty "IS_PERSONAL"
    @_parentToSet = @get "PARENT_FOLDER_ID"

    _.extend options,
      success: =>
        # HACK: remove link to "new" model in collection
        if isNew
          delete @collection?._byId["new"]

        unless options.pnotify is false
          @notifySuccess "saving", "done"

        origin.success? arguments...

        # change personality for all nested objects
        if personalityChanged
          @changePersonality @get "IS_PERSONAL"
          @notifyInfo "personality", "changed"

      error: =>
        unless options.pnotify is false
          @notifyError "saving", "failed"

        origin.error? arguments...

    super

  ###*
   * Change personality for all nested objects
   * @param {Boolean} personality flag
  ###
  changePersonality: (personality) ->
    @set "IS_PERSONAL", personality

    @reports.each (report) ->
      report.set "IS_PERSONAL", personality

    @collection?.each (folder) =>
      if @id is folder.get "PARENT_FOLDER_ID"
        folder.changePersonality personality

  ###*
   * Destroy report, also remove all nested folders
   * @note check if user can delete reports first
   * @override
  ###
  destroy: (options = {}) ->
    if  not @isNew() and
        not @can "delete"
      return false

    if not @isNew()
      error = options.error
      super _.extend options,
        error: =>
          # TODO: handle server error type code
          if @getActiveReports().length
            @notifyError "delete", "executing"
          error? arguments...

    else
      super

  ###*
   * Get reports with active runs
   * @return {Array} reports
  ###
  getActiveReports: ->
    @reports.filter (report) -> report.isActive()

  ###*
   * Get reports with failed runs
   * @return {Array} reports
  ###
  getFailedReports: ->
    @reports.filter (report) -> report.isFailed()

  ###*
   * Check if report is personal
   * @return {Boolean}
  ###
  isPersonal: ->
    1 is Number @get "IS_PERSONAL"

  islock: (data) ->
    not @can data.action or data

  ###*
   * Determine action possibility
   * @note fix iterations = 3
   * @todo write tests fix iterations will be >= 4
   * @param  {String} action
   * @return {Boolean} ability decision
  ###
  can: (action) ->
    origin = action
    action = "edit" if action in ["add", "copy", "privatize"]

    # Actions "add"/"copy" can be checked without model
    # via @collection.model::can, for example.
    # In this case @get will throw an error
    if @ instanceof exports.model
      id = @get("USER_ID")
      owner = not id or App.Session.currentUser().id is id

    access = helpers.can { action: action, type: "report" }

    # folders can't be executed
    if origin in ["execute", "cancel"]
      return false

    # just check privileges for some actions
    if origin in ["copy", "add"]
      return access

    if permission = access

      if origin is "privatize" and not owner
        permission = false

      else
        # do additional nested entities checks for some actions
        if origin in ["delete", "privatize"]
          nestedFolders = @collection?.where PARENT_FOLDER_ID: @get @idAttribute
          entities      = _.union @reports.models, nestedFolders or []

          # determine if any REPORT in folder can be deleted/privatized
          blocker = _.any entities, (entity) ->
            not entity.can origin

          if blocker
            permission = false

    # @log ":can", origin, permission,
    #   privilege  : "#{@priviledgesScope}:#{action}"
    #   access     : access
    #   owner      : owner or @get "USER_ID"
    #   entities   : entities
    #   permission : permission
    #   user       : App.Session.currentUser().id
    #   folder     : @id
    #   blocker    : blocker

    permission

  ###*
   * Stop active reports
  ###
  stop: ->
    for report in @getActiveReports()
      # syncronize to show one message
      report.stop()

  ###*
   * Run inactive reports
  ###
  run: ->
    for report in _.difference @reports.models, @getActiveReports()
      # syncronize to show one message
      report.run()


exports.collection = class ReportFoldersCollection extends TreeCollection

  model: exports.model

  url: (queryString = '') ->
    "#{App.Config.server}/api/selectionFolder
    ?sort[DISPLAY_NAME]=ASC
    &with=
    #{queryString}".replace /\s/g, ""

  comparator: "DISPLAY_NAME"

  initialize: ->
    super

  resolveNodeClass: (node, model) ->
    modifiers = ["_folder"]

    unless model.get("IS_PERSONAL") > 0
      modifiers.push "_public"

    modifiers.join " "

  ###*
   * Rebuild tree structure
   * @return {Object} - tree data
  ###
  rebuild: (options = {}) =>
    @_cleanup()
    @treeData = @_getNodes()
    @trigger "rebuild", @treeData unless options.silent
    @treeData

  ###*
   * Remove models and their children
   * @param {Array|Backbone.Model} models - model or models
   * @param {Object} options
  ###
  remove: (models, options = {}) ->
    models = _.isArray(models) and models or [models]
    for model in models
      children = @where PARENT_FOLDER_ID: model.id
      super
      for child in children
        child.trigger 'destroy', child, child.collection, options

  prepareNode: (node, model) ->
    node.folder   = true
    node

  makeKey: (model) ->
    "folder:#{model.id}"
