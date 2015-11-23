"use strict"

# ENTITIES
Report       = require "models/reports/report.coffee"
ReportFolder = require "models/reports/folder.coffee"
ReportRun    = require "models/reports/run.coffee"
ReportWidget = require "models/reports/widget.coffee"
Selection    = require "models/events/selections.coffee"

# VIEWS
TreeView      = require "views/reports/tree.coffee"
EmptyView     = require "views/reports/empty.coffee"
ReportView    = require "views/reports/report.coffee"
ReportRunView = require "views/reports/run.coffee"

ReportFolderContentView = require "views/reports/folder.coffee"

# DIALOGS
ReportWidgetView  = require "views/reports/dialogs/widget.coffee"
ReportHistoryView = require "views/reports/dialogs/history.coffee"
ReportFolderView  = require "views/reports/dialogs/folder.coffee"

helpers       = require "common/helpers.coffee"
storage       = require 'local-storage'
reportHelpers = require "helpers/report_helpers.coffee"

co = require "co"

class CometHandler

  ###*
   * Queue to show messages in correct order
   * @type {Array}
  ###
  _messagesQueue = []

  lsIgnoreKey = "reports:ignore:commet:update"

  ###*
   * Intermidiate states of report run
   * @type {Array}
  ###
  _runningStates = [
    'running'
  ]

  ###*
   * States to show link to report
   * @see #_runFlow
   * @type {Array}
  ###
  _finiteStates = [
    'error'
    'completed'
    'canceled'
  ]

  ###*
   * Report execution flow
   * @note represent all states
   * @type {Array}
  ###
  _runFlow = _runningStates.concat _finiteStates

  ###*
   * Reports are currently executed
  ###
  _executing = {}

  ###*
   * Get (or fetch) report and get it's name
   * @param  {Object} data - message data
   * @return {Promise}
  ###
  _getReportData = (data) ->
    new Promise (resolve, reject) ->

      # try to get data from message
      try
        _.extend data, JSON.parse data.DATA

      # data is not comprehensive
      if not data.DISPLAY_NAME

        # TODO: prerequisite to write data storage
        if report = App.request "reports:get:report", data.QUERY_REPORT_ID
          resolve _.extend data, report.toJSON()

        else
          report = new Report.model QUERY_REPORT_ID: data.QUERY_REPORT_ID
          report.fetch().then ->
            resolve _.extend data, report.toJSON()

  ###*
   * Get needed data from report model to fill message
   * @param  {Object} data - message data
   * @return {Promise}
  ###
  _fillMessage = (data) ->
    # resolve pnotify message type...
    msgType = if data.type is "error"
      "Error"
    else
      data.type in _finiteStates and "Success" or "Info"

    params = _makeParams data

    # find that message in queue
    msg = _.find _messagesQueue, (msg) ->
      msg.id is data.QUERY_REPORT_ID and msg.type is data.type

    if msg
      # fill queued message data
      msg.data = msgType: msgType, params: params

      # find all queued messages for current report
      queued = _.filter _messagesQueue, (msg) ->
        msg.id is data.QUERY_REPORT_ID

      # register flow msg`s in special registry
      # to avoid it`s secondary showing
      if msg.type in _runningStates
        _reportFlow = _executing[data.QUERY_REPORT_ID] ?= []
        if _.contains(_reportFlow, msg.type)
          msg.ignore = true
        else
          _reportFlow.push msg.type

      # if state is finite - clear running flow registry
      if msg.type in _finiteStates
        delete _executing[data.QUERY_REPORT_ID]

      # ensure the order is correct
      for _msg in queued
        order = _.indexOf _runFlow, msg.type
        if order >= 0
          # don't show message if more recent
          # and actual message about flow change was pushed
          if _.indexOf(_runFlow, _msg.type) < order
            _msg.ignore = true

    data

  ###*
   * Form params for pnotify call
   * @param  {Object} data message data
   * @return {Object} params object
  ###
  _makeParams = (data) ->
    data = ReportRun.model::parseErrors data

    params =
      title : App.t "reports.pnotify.run_execution", data
      text  : App.t "reports.pnotify.run_execution_#{data.type}", data

    # Add link to report if needed
    if data.type in _finiteStates and not data.currentlyViewed
      params.hide = false

      # TODO: remove link from localization
      params.text += " " + App.t "reports.pnotify.run_execution_link",
        link: "/reports/#{data.QUERY_REPORT_ID}"

    params

  ###*
   * Show all pnotify messages with delay
   * Business case: report canceling or report running
   * will affect 2 commet pushes, which will initiate pnotify twice,
   * one by one. To prevent it, use delay
   * @note used only by reports
  ###
  _notify = _.debounce ->
    while msg = _messagesQueue.shift()
      if not msg.ignore
        App.Notifier["show#{msg.data.msgType}"]? msg.data.params
  , 500

  ###*
   * Listen global event bus
  ###
  constructor: ->
    App.vent.on "reports:handle:comet:message", @handle

  ###*
   * Create logger if isn't exist and
   * print message to console with debug.js
  ###
  log: helpers.createLogger "reports_commet_handler"

  ###*
   * Handle commet message, add it to message queue, request
   * for report name by it's id and show message.
   * @param  {Object} message - socket client incoming message
  ###
  handle: (module, data) =>
    switch module

      when "query_reporter"
        reportId = data.QUERY_REPORT_ID

        @log ":handle", reportId, data #, ignored

        # Determine if proper run is currently viewed
        data.currentlyViewed = App.reqres.request "reports:update:run", _.omit data, 'type'

        # queue message
        _messagesQueue.push id: data.QUERY_REPORT_ID, type: data.type, data: {}

        _getReportData data
        .then _fillMessage
        .then _notify

      when "query_reporter_generate"
        if data.type is "completed"
          params = $.param _.omit data, 'type'
          url    = "#{App.Config.server}/api/selectionReport/getReport?#{params}"
          window.location.href = url
        else
          App.Notifier.showError
            title : App.t "reports.pnotify.report_download",
            text  : App.t "reports.pnotify.report_download_failed"


App.module "Reports",
  startWithParent: false
  define: (Module, App, Backbone, Marionette, $) ->

    ###*
     * Reports module controller (singleton)
    ###
    module.exports = class ReportsController extends Marionette.Controller

      ###*
       * Reporter that serves reports execution flow
       * @type {CometHandler}
      ###
      @cometHandler = new CometHandler

      ###*
       * Flag to determine if minimal batch of required data to
       * render any view in section was fetched from server
       * @type {Boolean}
      ###
      ready: false

      ###*
       * Local storage key to remember current folder for entity adding
       * @note used to restore page state
       * @type {String}
      ###
      remFolderKey: "reports:folder:to:add:to"

      ###*
       * Global events to handle
       * @type {Object}
      ###
      events:

        # listen reports
        "reports:report:save" : "_onReportSave"
        "reports:report:run"  : "_onReportRun"

        # listen folders
        "reports:folder:save"    : "_onFolderSave"
        "reports:folder:destroy" : "_onFolderDestroy"

        # common entity operations
        "reports:remove:entity"  : "_removeEntity"
        "reports:copy:entity"    : "_copyEntity"
        "reports:register:query" : "_registerQuery"

        # local storage events
        "reports:remember:folder" : "_rememberFolder"
        "reports:forgot:folder"   : "_forgotFolder"
        "reports:cleanup:storage" : "_cleanupStorage"

      ###*
       * Global reqres handlers
       * @type {Object}
      ###
      handlers:
        "reports:update:run" : "_onRunUpdate"
        "reports:get:query"  : "_getQuery"
        "reports:get:report" : "_getReport"

      ###*
       * Init controller:
       *   - make aliases for App Layout regions
       *   - initialize collections
       *   - create event listeners
      ###
      initialize: ->
        @locale = App.t "reports", returnObjectTrees: true

        # make refs to regions
        @regions = _.reduce ["sidebar", "content", "modal"], (m, r) ->
          m[r] = App.Layouts.Application[r]; m
        , {}

        # collections
        # TODO: global storage
        @folders = new ReportFolder.collection []
        @reports = new Report.collection []
        @queries = new Selection.collection [],
          overrideParams: true
          params:
            with: "status"

        @queries.fetch()
        .then =>
          # sync few fetches
          $.when @folders.fetch(), @reports.fetch()
            .then  =>
              @log ":synced", arguments
              # trigger all data is ready
              @ready = true
              @_onReady()

        # add event handlers
        for event, handler of @events
          @listenTo App.vent, event, @[handler]

        # set reqres handlers
        for key, handler of @handlers
          App.reqres.setHandler key, @[handler].bind @

        @listenTo @regions.content, "show", @_toggleTreeToolbar

      ###*
       * Cleanup reqres handlers
      ###
      onDestroy: ->
        for key, handler of @handlers
          App.reqres.removeHandler key

      ###################################################################
      # PROTECTED

      ###*
       * Route handlers presenter involves common dom and state
       * manipulations for each handler e.g. sidebar tree view rendering
       * @param  {String} type - route main entity type (report/folder)
       * @param  {Function} handler - route handler
      ###
      _presenter = (type, handler) ->
        (id, tail...) ->

          handle = =>

            # render tree in sidebar
            @_renderTree()

            # get active node (to get model)
            node = @tree.getNode "#{type}:#{id}"

            # not found case
            if !!id and
                id isnt "new" and
                not node
              storage.remove "last:viewed:object"
              return App.vent.trigger "nav", "reports"

            # save args in context
            args = [id]
              .concat tail
              .concat node?.data?.model

            # activate report/folder if it exists
            if node
              @_setActiveNode type, id

            # do things
            handler.apply @, args

            # activate new report/folder
            if not node
              @_setActiveNode type, id

            if folder = @tree.getActiveFolder()
              @tree.expand folder

            @trigger "route", args...

          if @ready # all needed data was fetched
            handle()
          else
            # do things after fetch
            @_onReady = handle

            # empty regions
            for name, region of @regions
              region.empty()

      ###*
       * Localization strings slice
       * @type {Object}
      ###
      _locale = _.memoize -> App.t "reports", returnObjectTrees: true

      ###################################################################
      # PRIVATE

      ###*
       * Activate node in tree by type and id
      ###
      _setActiveNode: (type, id) ->
        if node = @tree.getNode "#{type}:#{id}"
          node.setActive true, noEvents: true

      ###*
       * Get query from collection
       * @param  {Number} id
       * @return {Backbone.Model}
      ###
      _getQuery: (id) ->
        @queries.get id

      ###*
       * Get report from collection
       * @param  {Number} id
       * @return {Backbone.Model}
      ###
      _getReport: (id) ->
        @reports.get id

      ###*
       * Add query to queries collectio
       * @param  {Backbone.Model} query
      ###
      _registerQuery: (query) ->
        @queries.add query

      ###*
       * Render tree view in sidebar, that represents
       * reports & folders hierarchy
      ###
      _renderTree: ->
        @tree ?= new TreeView
          container : "[data-tree]"
          autoSort  : true
          folders   : @folders
          reports   : @reports
        unless @regions.sidebar.currentView instanceof TreeView
          @regions.sidebar.show @tree

      ###*
       * Disable toolbar while report editing
       * @param  {Backbone.View} view - content view
      ###
      _toggleTreeToolbar: (view) ->
        if view instanceof ReportView
          @tree.disableToolbar()
        else
          @tree.enableToolbar()

      ###*
       * Check if current content view is actual and there are
       * no needs for rerendering
       * @param  {Class} viewClass
       * @param  {Object} conditions - hash of models to compare
       * @return {Boolean}
      ###
      _isActualContent: (viewClass, conditions) ->
        if view = @regions.content.currentView

          # determine the curren view is action
          properClass = view? and view instanceof viewClass

          imProperModels = _.any conditions, (model, attr) ->
            not view[attr]? or not (view[attr] is model or view[attr].id is model)

          properClass and not imProperModels

        else
          false

      ###*
       * Render form to edit existing or new report
       * @param  {String|Number} id - report id (maybe "new")
       * @param  {Backbone.Model} report
      ###
      _renderReport: (reportId) ->
        report = @_getReport reportId
        if reportId is "new"
          @addReport reportId, report
        else
          @editReport reportId, report

      ###*
       * Show widget modal dialog right after
       * report should be rendered in content
       * @param  {Backbone.Model} widget
       * @param  {Backbone.Model} report
      ###
      _renderWidget: (widgetId, reportId, tab) ->
        @_renderReport reportId

        report = @_getReport reportId
        widget = report?.widgets.get widgetId

        if not widget
          widget = new ReportWidget.model {
            QUERY_REPORT_ID: reportId
          }

        @regions.modal.show new ReportWidgetView
          model   : widget
          report  : report
          tab     : tab
          queries : @queries


      ###*
       * Show proper report run for report
       * @param {Backbone.Model} report
       * @param {Number|String} runId - may be an id or "last" string
      ###
      _renderReportRun: (report, runId) ->

        if not (@_isActualContent ReportRunView, report: report.id, model: runId)

          # TODO: show spinner
          @regions.content.empty()

          @_fetchRunData(report, runId).done =>

            run = report.runs.get(runId) or new ReportRun.model
              QUERY_REPORT_ID: report.id

            @regions.content.show new ReportRunView
              model    : run
              report   : report
              showLast : runId is "last"

            if @regions.modal.currentView instanceof ReportHistoryView
              @regions.modal.empty()

            storage "last:viewed:object", "/reports/#{report.id}"

      _fetchRunData: (report, runId) ->
        dfd = $.Deferred()

        _.defer ->
          co ->
            if runId is "last" or not report.runs.get(runId)
              response = yield report.fetchRuns(runId)

            run = report.runs.get(runId)

            if runId isnt "last" and not run
              # if even after fetch there are no such run
              # then it was deleted, so redirect
              return dfd.reject App.vent.trigger "nav", "reports"

            if run
              # check if run data was already fetched
              if _.isEmpty run.get("DATA")
                yield run.fetch()

            dfd.resolve()

        $.when(report.fetch(), dfd)

      ###*
       * Put current folder for entity adding in LS
       * @param  {Number} id
      ###
      _rememberFolder: (id) ->
        storage @remFolderKey, id

      ###*
       * Remove current folder for entity adding from LS
      ###
      _forgotFolder: ->
        storage.remove @remFolderKey

      ###*
       * Remove keys from LS by pattern(s)
       * @param  {String|Array} pattern(s)
      ###
      _cleanupStorage: (patterns...) ->
        regexes = _.map patterns, (pattern) ->
          new RegExp "reports:#{pattern}"

        for key, val of localStorage
          for re in regexes
            if re.test key
              storage.remove key

      ###*
       * Create new report/folder model. Try to get cached data from
       * Local Storage to determine to what folder user wanted
       * to add new report/folder before page was refreshed/crashed
       * @return {Backbone.Model} report model
      ###
      _createEntity: (type, modelClass) ->
        if folderId = storage @remFolderKey

          # check if folder exists
          unless @tree.getNode "folder:#{folderId}"
            @_forgotFolder()
            folderId = null

        # try to get cache from local storage
        cache = storage "reports:#{type}:new"

        data = cache or
          USER_ID      : App.Session.user.get "USER_ID"
          DISPLAY_NAME : _locale()[type].new

        _.extend data, switch type
          when "folder"
            PARENT_FOLDER_ID: folderId
          else
            FOLDER_ID: folderId

        # inherit personality
        if folderId
          data.IS_PERSONAL = @folders.get(folderId).get "IS_PERSONAL"

        model = new modelClass data

      ###*
       * Remove report/folder with confirmation
       * @param  {String} type - entity type
       * @param  {Backbone.Model} model
       * @param  {Object} options = {} options for save
      ###
      _removeEntity: (type, model, options = {}) ->
        data = _.extend name: model.get(model.nameAttribute),
          options.confirmData

        opts =
          title   : options.title or App.t "reports.#{type}.remove_title"
          content : options.content or App.t "reports.#{type}.remove_text", data

        App.Helpers.confirm _.extend opts,
          accept: ->
            model.destroy _.defaults options,
              wait: true

      ###*
       * Copy folder with all nested reports
       * @param  {Backbone.Model} model
       * @param  {Object} options = {}
       * @return {jQuery.Deferred} promise
      ###
      _copyFolder: (model, options = {}) ->
        user      = App.Session.currentUser().id
        isUnique  = false
        parent    = model.get("PARENT_FOLDER_ID")
        neighbors = @folders.where "PARENT_FOLDER_ID": parent

        options   = _.defaults _.clone(options),
          full  : true
          copy  : true
          chown : user
          safe  : true

        if node = @tree.getActiveNode()

          # FIXME: don't fetch widgets with report api,
          # use new widget api (#KAKTYZ-9212)
          promises = []
          @tree.visitItems node, (node) ->
            promises.push node.data.model.fetch()

          $.when(promises...).then =>

            data = model.toJSON options
            data.PARENT_FOLDER_ID = parent

            folder = new ReportFolder.model _.cloneDeep data

            while not isUnique

              # generate folder name
              name = App.Helpers.generateCopyName folder.getName(), (name) ->
                _.any neighbors, (folder) ->
                  name is folder.get "DISPLAY_NAME"

              folder.set DISPLAY_NAME: name

              if _.keys(folder.validate() or {}).join().match /NAME/
                postfix = _.capitalize App.t('global.сopied')
                name    = folder.get "DISPLAY_NAME"
                postfix = name.slice name.indexOf(postfix) - 1
                name    = name.slice(0, folder.maxNameLength - postfix.length - 1) + "…"

                folder.set DISPLAY_NAME: name

              else
                isUnique = true

            # for audit
            data.copy = true
            data.DISPLAY_NAME = folder.get "DISPLAY_NAME"

            _.defaults options,
              wait    : true
              pnotify : false

              success: (folder) =>
                $.when @reports.fetch(merge: true), @folders.fetch(merge: true)
                  .then ->
                    folder.notifySuccess "copy", "done"

              error: ->
                folder.notifyError "copy", "fail"

            options.attrs = data

            @log ":copyOptions", options
            folder.save null, options

      ###*
       * Copy report by going to report creation form,
       * or by saving model copy without editing
       * @param  {Backbone.Model} model
       * @param  {Object} options = {}
       * @options options {Boolean} force - flag to copy & save without editing
       * @return {jQuery.Deferred} promise
      ###
      _copyReport: (model, options = {}) ->
        data = model.toJSON()

        if @options.force
          delete data.QUERY_REPORT_ID
        else
          data.QUERY_REPORT_ID = "new"

        data.USER_ID = App.Session.currentUser().id
        if options.folder
          data.FOLDER_ID = options.folder

        data.DISPLAY_NAME = App.Helpers.generateCopyName data.DISPLAY_NAME, (name) =>
          _.compact([
            # find reports with same name in root
            _.any @reports.models, (report) ->
              name is report.get "DISPLAY_NAME"

            # find reports with same name in folders
            _.any @folders.find (folder) ->
              folder.reports.find (report) ->
                name is report.get "DISPLAY_NAME"
          ]).length

        # Process widgets
        if data.widgets
          for widget in data.widgets

            if options.force
              # remove id to sync correctly
              delete widget.QUERY_REPORT_WIDGET_ID
            else
              # create "new" (temp) id
              widget.QUERY_REPORT_WIDGET_ID = _.uniqueId "new"

            # QUERY_ID is all we need
            delete widget.query

        data.copy = true

        # save model without editing
        if options.force
          newReport = new Report.model data

          if folder = newReport.get "FOLDER_ID"
            @folders.get folder
              .reports.add newReport

          newReport.save null, _.extend options,
            wait: true
            error: ->
              newReport.destroy()

        else
          # HACK: because new report should be added
          # with @_createEntity, which should be
          # called by @addReport after navigation
          # (So value from local storage should be used)
          # TODO: think about how to make it
          # more transparent and remove this dirty hack
          @_rememberFolder model.get "FOLDER_ID"

          storage "reports:report:new", data
          App.vent.trigger "nav", "reports/new/edit"

      _copyWidget: (model, options = {}) ->
        newModel = new ReportWidget.model _.extend model.toJSON(),
          QUERY_ID : null
          USER_ID  : App.Session.currentUser().id
          copy     : true

          # create local unique id to cache few models
          QUERY_REPORT_WIDGET_ID : ReportWidget.model::generateId()

        if model.collection
          newName = "#{model.get('DISPLAY_NAME')} #{$.t 'reports.copy'}"
          model.collection.resolveUniqueWidgetName newModel, newName
          model.collection.add newModel

        newModel

      ###*
       * Create cache for model and navigate to proper route
       * to create new model with predefined cache
       * @param  {String} type - entity type
       * @param  {Backbone.Model} model
      ###
      _copyEntity: (type, model, options = {}) ->
        @["_copy#{_.capitalize type, true}"] model, options

      ###*
       * Add report to report to folder/root
       * @param  {Backbone.Model} model - report model
       * @param  {Boolean} isNew - created(true)/saved(false) flag
      ###
      _onReportSave: (model) =>
        @reports.add model

      ###*
       * Add new folder to collection
       * @param  {Backbone.Model} model - folder model
       * @param  {Boolean} isNew - created(true)/saved(false) flag
      ###
      _onFolderSave: (model) =>
        @folders.add model

      ###*
       * Go back or to root when folder destroyed
       * @param  {Backbone.Model} model
      ###
      _onFolderDestroy: (model) ->
        @folders.remove model
        @reports.remove @reports.filter (report) ->
          report.get("FOLDER_ID") is model.id

      ###*
       * Run report
       * @param  {Backbone.Model} model
      ###
      _onReportRun: (model) ->
        model.execute()

      ###*
       * Check if current view is proper run view
       * @param  {Object} data - report run model data
       * @return {Boolean} true if run is currently viewed, false otherwise
      ###
      _onRunUpdate: (data) ->
        runId    = data.QUERY_REPORT_RUN_ID
        reportId = data.QUERY_REPORT_ID

        if report = @_getReport reportId
          if run = report.runs.get runId
            run.set run.parse(data)

            # update buttons accessability
            @tree.updateToolbar()

            if @regions.content.currentView?.model.id is runId
              return true

        false

      ###################################################################
      # PUBLIC

      ###*
       * Show empty view
      ###
      show: _presenter "empty", ->
        if path = storage("last:viewed:object")
          App.vent.trigger "nav", path
        else
          @tree.resetNodesActivity()
          @regions.content.show new EmptyView

      ###*
       * Show last report run view for specified (by id) report
       * @param  {Number} id - report id
      ###
      showReport: _presenter "report", (id, report) ->
        @_renderReportRun report, "last"

      ###*
       * Show specified by id report run info
       * @param  {Number} id - report id
       * @param  {Number} rid - report run id
       * @param  {Backbone.Model} report - report run id
      ###
      showReportRun: _presenter "report", (id, rid, report) ->
        @_renderReportRun report, rid

      ###*
       * Show edit report view
       * @param  {Number} id - report id
      ###
      editReport: _presenter "report", (id, report) ->
        if not (@_isActualContent ReportView, model: report.id)
          report.fetch().then =>
            @regions.content.show new ReportView
              model: report

      ###*
       * Show report edit form for new report in content region.
       * Highlight proper folder in tree view
      ###
      addReport: _presenter "report", (id, report) ->
        if not (@_isActualContent ReportView, model: "new")

          folder = @tree.getActiveFolder()
          report = @_createEntity "report", Report.model

          @tree.expand folder
          @reports.add report

          # render
          @regions.content.show new ReportView
            model: report

      # MODALS

      ###*
       * Show modal dialog for reports folder adding
       * @param  {Number} id - folder id
       * @param  {Backbone.Model} folder
      ###
      showFolder: _presenter "folder", (id, folder) ->
        @regions.content.show new EmptyView
        storage "last:viewed:object", "/reports/folders/#{id}"

        # TODO: show Valeronium brainstorm results later (KAKTYZ-6363)
        # @regions.content.show new ReportFolderContentView
        #   model: folder

      ###*
       * Show modal dialog for reports folder adding
      ###
      addFolder: _presenter "folder", ->

        parent = @tree.getActiveFolder()
        folder = @_createEntity "folder", ReportFolder.model

        unless id = folder.get "PARENT_FOLDER_ID"
          folder.set "PARENT_FOLDER_ID", parent?.data.model.id

        # show in tree
        @folders.add folder

        # FIXME remove force rebuild
        @tree.rebuild()

        # render
        @regions.modal.show new ReportFolderView
          model: folder

      ###*
       * Show modal dialog for reports folder adding
       * @param  {Number} id - report id
       * @param  {Backbone.Model} folder
      ###
      editFolder: _presenter "folder", (id, folder) ->
        @regions.modal.show new ReportFolderView
          model: folder

      ###*
       * Show modal dialog for report runs viewing
       * @param  {Number} id - report id
      ###
      showReportRuns: _presenter "report", (id, report) ->
        # @showReport id, report

        report.fetchRuns("all").then =>
          @regions.modal.show new ReportHistoryView
            model: report
            collection: report.runs

      ###*
       * Show modal widget dialog
       * @param  {Number} id - report id
       * @param  {Number} widgetId - widget id
       * @param  {String} tab - active tab
       * @param  {Backbone.Model} report
      ###
      editWidget: _presenter "report", (reportId, widgetId, tab, report) ->
        @_renderWidget widgetId, reportId, tab

    #######################################################################
    # Initializers And Finalizers

    Module.addInitializer ->
      App.Controllers.Reports = new ReportsController()

    Module.addFinalizer ->
      App.Controllers.Reports.destroy()
      delete App.Controllers.Reports
