"use strict"

BaseCrawlerModel  = require "models/crawler/base.coffee"
TaskSessions      = require "models/crawler/task_sessions.coffee"
TaskStatus        = require "models/crawler/task_status.coffee"


_fileFilters = [
  "doc", "docx", "xls", "xlsx", "ppt", "pptx",
  "odt", "ods", "odp", "pdf", "rtf", "tnef",
  "htm", "html", "xml", "txt", "emf"
]

_localAttributes = [
  'sharepointVersion'
  'sharepointUrl'
  'sharepointTarget'
  'filterPath'
  'targets'
  'lastLaunch'
  'localFormat'
]

exports.Model = class TaskModel extends App.Helpers.virtual_class(
  BaseCrawlerModel
  App.Common.ValidationModel
)

  SCAN_POLICIES           : ["local", "network", "sharepoint"]
  SHAREPOINT_VERSIONS     : ["2007", "2010", "2013"]
  SCAN_MODES              : ["AllFolders", "AllExceptForbidden", "OnlyAllowed"]
  SCHEDULE_TYPES          : ["Manual", "Weekly", "Daily", "Monthly", "Once"]
  SCHEDULE_DAYS           : ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  FILE_FILTERS            : _fileFilters
  MOUNTH_DAYS             : _.union [1..31], ['last']

  urlRoot                 : "#{App.Config.server}/api/crawler/task"

  status_worker: null

  validate: (value) ->
    err = {}

    if value.localFormat
      value = @_parseFromModel(value)

    switch value.scanPolicy
      when "DBFileStorage"
        unless value.Targets.Target[0].hostname.split("\\")[0]
          err['sharepointTarget[address]'] = App.t 'crawler.missing_sharepoint_db_address'
        unless value.Targets.Target[0].hostname.split("\\")[1]
          err['sharepointTarget[name]'] = @t 'crawler.missing_sharepoint_db_name'

      when "SPFileStorage"
        unless value.Targets.Target[0].hostname
          if value.FileSystem.protocol is "SPFS"
            err['sharepointUrl'] = @t 'crawler.missing_sharepoint_server'
          else
            err['sharepointTarget[address]'] = @t 'crawler.missing_sharepoint_server'

      else
        unless value.Targets.Target.length
          err['targets'] = @t 'crawler.missing_targets'

    if not value.name
      err.name = @t 'crawler.task_details_name_required_error'
    else
      if not value.name.match(/^[^\s]+[а-яёa-z0-9\.\,\-\_\:\;\(\)\s]+$/i)?
        err.name = @t 'crawler.task_details_name_format_validation_error'

      if finded = @collection.findWhere({name: value.name})
        if not @isNew() and @id isnt finded.id
          @t "crawler.job_already_exists"

      if value.name.length > 256
        @t "crawler.job_name_length_validation_error"

    if value.scanMode is 'OnlyAllowed' and value.Filters.AllowedPathFilter.path is ""
      err["filterPath"] = @t 'crawler.task_details_filter_path_missing'

    if value.scanMode is 'AllExceptForbidden' and value.Filters.ForbiddenPathFilter.path is ""
      err["filterPath"] = @t 'crawler.task_details_filter_path_missing'

    if value.FileSystem.Credentials.useLocal is 'false'
      unless value.FileSystem.Credentials.login
        err["FileSystem[Credentials][login]"] = @t 'crawler.task_details_login_required_error'

    unless /^\d+$/.test value.Filters.SizeFilter.min
      err["Filters[SizeFilter][min]"] = @t "crawler.job_details_common_size_validation"

    unless /^\d+$/.test value.Filters.SizeFilter.max
      err["Filters[SizeFilter][max]"] = @t "crawler.job_details_common_size_validation"

    if parseInt(value.Filters.SizeFilter.max , 10) < parseInt(value.Filters.SizeFilter.min, 10)
      err["Filters[SizeFilter][max]"] = @t 'crawler.job_details_common_size_order_error'

    if _.isEmpty err then null else err

  defaults:
    description             : ""
    policy                  : "Default"
    scanPolicy              : "network"
    scanPolicyDescription   : ""

    recipient               : "expressd"
    scanMode                : "AllFolders"

    Targets                 :
      Target                : []

    Schedule:
      type                  : "Manual"

    FileSystem:
      scanAdminShares       : "false"
      protocol              : "SMB"
      scriptId              : "-1"
      scriptName            : ""
      Credentials:
        useLocal            : "true"
        login               : ""
        password            : ""
      excludeSystemFolders  : "true"

    Filters                 :
      AllowedPathFilter     :
        path                : ""
      ForbiddenPathFilter   :
        path                : ""
      MaskFilter            : _fileFilters.join(",")
      SizeFilter            :
        min                 : 0
        max                 : 10000
        restrictMaxSize     : "true"
        restrictMinSize     : "false"

  type: "task"

  islock: Backbone.Model::islock

  comparator : (m1, m2) ->
    [
      name1
      name2
    ] =
      _.map arguments, (model) ->
        model.get "name"
        .toLowerCase()

    sorted = [name1, name2].sort()

    if name1 is sorted[0]
      -1
    else
      1

  initialize: ->
    @status   = new TaskStatus(task: @)
    @sessions = new TaskSessions.Collection(task: @)

  save: (key, value, options) ->
    if (_.isObject(key) or key is null)
      attrs = key
      options = value
    else
      attrs = {}
      attrs[key] = value

    attrs.localFormat = true
    newAttrs = @_parseFromModel(attrs)

    for elem in _localAttributes
      @unset elem, {silent: true}

    Backbone.Model.prototype.save.call @, newAttrs, options

  parse: (response) ->
    response = super
    @_parseToModel(response)

  getName: ->
    @name

  purgeHashes: ->
    $.ajax "#{@urlRoot}/#{@id}/hashes",
      success: =>
        App.Notifier.showWarning
          text : App.t 'crawler.was_purge_hashes_job',
            name: @get("name")
      error: ( jqXHR, textStatus, errorThrown ) ->
        App.Notifier.showError
          text : textStatus
      type: "DELETE"

  stop: ->
    if @collection.scanner.get("online") is "true"
      $.ajax
        url  : "#{@urlRoot}/#{@id}/stop"
        type : "PUT"
        success: =>
          @_stopPooling()
        error: ( jqXHR, textStatus, errorThrown ) =>
          App.Notifier.showError
            text : App.t 'crawler.stop_task_error',
              name: @get 'name'

  start: ->
    if @collection.scanner.get("online") is "true"
      $.ajax
        url   :"#{@urlRoot}/#{@id}/start"
        type  : "PUT"
        success: =>
          @collection.fetch()
          @_startPooling()
        error: ( jqXHR, textStatus, errorThrown) ->
          switch jqXHR.responseText
            when "Locked"
              App.Notifier.showError
                text : App.t 'crawler.job_locked',
                  name: @get("name")
            when "Running"
              App.Notifier.showError
                text : App.t 'crawler.job_started',
                  name: @get("name")

  # PRIVATE

  _fetchTaskData: ->
    @status.fetch
      disableNProgress: true
    @sessions.fetch
      disableNProgress: true

  _startPooling: ->
    @_stopPooling()

    @timer = setInterval =>
      @_fetchTaskData()
    , 5000

  _stopPooling: ->
    clearInterval @timer if @timer
    @timer = null

    @_fetchTaskData()

  _extractHostname: (url) ->
    if url.indexOf("://") > -1
      hostname = url.split('/')[2]
    else
      hostname = url.split('/')[0]

    hostname = hostname.split(':')[0]

  _parseToModel: (response) ->
    # check parsing needless
    if response.localFormat
      return _.cloneDeep response

    switch response.scanPolicy
      when 'FilesShare'
        response.scanPolicy = response.FileSystem.scanAdminShares is "true" and "local" or "network"

      when 'DBFileStorage'

        response.scanPolicy = "sharepoint"

        if response.FileSystem.scriptId isnt "-1"
          response.sharepointVersion = do ->
            switch response.FileSystem.scriptId
              when "1" then "2007"
              when "2" then "2010"

      when 'SPFileStorage'
        response.scanPolicy = "sharepoint"
        response.sharepointVersion = "2013"

    if response.last_launch?
      response.lastLaunch = moment(response.last_launch)

    if _.isArray response.Filters.MaskFilter
      response.Filters.MaskFilter = _.map response.Filters.MaskFilter, (filter) ->
        filter.mask[2..]
      .join(",")
    else
      response.Filters.MaskFilter = response.Filters.MaskFilter.mask[2..]

    if response.scanPolicy is "sharepoint"
      target = response.Targets.Target
      target = target instanceof Array and target[0] or target

      if response.sharepointVersion is "2013"
        if target
          response.sharepointUrl = target.uri
      else
        if target
          target_arr = target.hostname.split "\\"
          response.sharepointTarget =
            address: _.initial(target_arr).join('\\')
            name: _.last target_arr
    else
      response.Targets.Target ?= []
      if _.isPlainObject(response.Targets.Target) then response.Targets.Target = [response.Targets.Target]

      response.targets = _.map response.Targets.Target, (target) ->
        TYPE  : target.type?.toLowerCase()
        ID    : target.uri
        NAME  : target.hostname

    response.Filters.SizeFilter.min = response.Filters.SizeFilter.min / 1024
    response.Filters.SizeFilter.max = response.Filters.SizeFilter.max / 1024

    if response.Schedule.delayStart
      response.Schedule.delayStart = moment(response.Schedule.delayStart, 'YYYY-DD-MM').format("DD/MM/YYYY")

    if response.scanMode is 'AllExceptForbidden'
      response.filterPath = response.Filters.ForbiddenPathFilter.path
    else if response.scanMode is "OnlyAllowed"
      response.filterPath = response.Filters.AllowedPathFilter.path

    response.localFormat = true

    response

  _parseFromModel: (attributes) ->
    attrs = _.cloneDeep(attributes or @attributes)

    # check parsing needless
    if not attrs.localFormat
      return attrs

    data  = _.defaultsDeep {}, attrs, @defaults

    if attrs.id
      data.taskGuid = attrs.id

    if attrs.scanPolicy is "sharepoint"
      if attrs.sharepointVersion is "2013"
        data.scanPolicy = "SPFileStorage"
        data.FileSystem.protocol = "SPFS"
        data.FileSystem.scanAdminShares = "false"
        data.FileSystem.scriptId = "3"
        data.FileSystem.scriptName = "SharePoint #{attrs.sharepointVersion}"
      else
        data.scanPolicy = "DBFileStorage"
        data.FileSystem.protocol = "DBFS"
        data.FileSystem.scanAdminShares = "false"
        data.FileSystem.scriptId = do ->
          switch attrs.sharepointVersion
            when "2007" then "1"
            when "2010" then "2"
        data.FileSystem.scriptName = "SharePoint #{attrs.sharepointVersion}"

    else
      data.scanPolicy = "FilesShare"
      data.FileSystem.protocol = "SMB"
      data.FileSystem.scanAdminShares = (attrs.scanPolicy is "local").toString()

    # Если это Sharepoint
    data.Targets ?= []

    switch data.scanPolicy
      when "DBFileStorage"
        data.Targets.Target = [
          hostname  : "#{attrs.sharepointTarget.address}\\#{attrs.sharepointTarget.name}"
          type      : "WorkstationManual"
          uri       : "#{attrs.sharepointTarget.address}\\#{attrs.sharepointTarget.name}"
        ]

      when 'SPFileStorage'
        data.Targets.Target = [
          hostname  : @_extractHostname attrs.sharepointUrl
          type      : "WorkstationManual"
          uri       : attrs.sharepointUrl
        ]

      else
        attrs.targets ?= []
        data.Targets.Target = attrs.targets.map (target) ->
          hostname: target.NAME
          type: _.capitalize target.TYPE
          uri: target.ID

    delete data.targets

    data.Filters.SizeFilter.min = data.Filters.SizeFilter.min * 1024
    data.Filters.SizeFilter.max = data.Filters.SizeFilter.max * 1024

    data.Filters.SizeFilter.restrictMaxSize = (attrs.Filters.SizeFilter.max not in ["", "0"]).toString()
    data.Filters.SizeFilter.restrictMinSize = (attrs.Filters.SizeFilter.min not in ["", "0"]).toString()

    data.Filters.MaskFilter = _.map data.Filters.MaskFilter.split(","), (filter) ->
      enabled   : "true"
      mask      : "*.#{filter}"

    if data.scanMode is "AllExceptForbidden"
      data.Filters.ForbiddenPathFilter.path = data.filterPath
    else if data.scanMode is "OnlyAllowed"
      data.Filters.AllowedPathFilter.path = data.filterPath

    # Convert boolean to string
    data.FileSystem.excludeSystemFolders = Boolean(data.FileSystem.excludeSystemFolders).toString()
    data.FileSystem.Credentials.useLocal = Boolean(data.FileSystem.Credentials.useLocal).toString()

    if data.Schedule.delayStart
      data.Schedule.delayStart = moment(data.Schedule.delayStart, "DD/MM/YYYY").format('YYYY-DD-MM')

    switch data.Schedule.type
      when 'Manual'
        delete data.Schedule.timeOfDay
        delete data.Schedule.dayOfTheWeek
        delete data.Schedule.dayOfMonth

      when 'Daily'
        delete data.Schedule.dayOfTheWeek
        delete data.Schedule.dayOfMonth

      when 'Weekly'
        delete data.Schedule.dayOfMonth

      when 'Once'
        delete data.Schedule.dayOfMonth
        delete data.Schedule.dayOfTheWeek

    result = _.omit data, _localAttributes

    result

exports.Collection = class TaskCollection extends Backbone.Collection

  model: exports.Model

  _TaskDeleted: (id) ->
    model = @get(id)

    return unless model

    @remove(model)

    App.Notifier.showWarning
      text : App.t 'crawler.job_deleted',
        name: model.get("name")

  _TaskUpdated: (task_id, data) ->
    model = @get(task_id)

    return unless model

    model.set model.parse(data)

    App.Notifier.showWarning
      text : App.t 'crawler.job_edited',
        name: model.get("name")

  _TaskUnlocked: (id) ->
    model = @get(id)

    return unless model

    model.set "locked", "false"

    App.Notifier.showWarning
      text : App.t 'crawler.job_unlocked',
        name: model.get("name")

  _TaskFinished: (id) ->
    @_TaskStopped id, true

  _TaskStopped: (id, is_finished) ->
    model = @get(id)

    return unless model

    model._stopPooling()

    @fetch
      disableNProgress: true
      reset    : false

    App.Notifier.showWarning
      text : App.t(
        if is_finished
          "crawler.job_finished"
        else
          "crawler.job_stopped"

        name: model.get("name")
      )

  _TaskStarted: (id) ->
    model = @get id

    return unless model

    @fetch
      disableNProgress: true
      reset : false

    App.Notifier.showWarning
      text : App.t 'crawler.job_started',
        name: model.get("name")

  _TaskLocked: (id, data) ->
    model = @get id

    return unless model

    model.set
      locked : "true"
      owner  : data

    App.Notifier.showWarning
      text : App.t 'crawler.job_locked',
        name: model.get("name")

  _TaskAdded: (task_id, data) ->
    unless @get(task_id)?
      parsed = @model::parse(data)

      @add(parsed)

      App.Notifier.showWarning
        text : App.t 'crawler.job_added',
          name: @get(task_id).get("name")

  initialize: (models, options) ->
    {@scanner} = options

    @listenTo @, "TaskDeleted", @_TaskDeleted
    @listenTo @, "TaskUpdated", @_TaskUpdated
    @listenTo @, "TaskUnlocked", @_TaskUnlocked
    @listenTo @, "TaskFinished", @_TaskFinished
    @listenTo @, "TaskStopped", @_TaskStopped
    @listenTo @, "TaskStarted", @_TaskStarted
    @listenTo @, "TaskLocked", @_TaskLocked
    @listenTo @, "TaskAdded", @_TaskAdded

  url: ->
    throw new Error("Missing scanner!") unless @scanner

    "#{App.Config.server}/api/crawler/scanner/#{@scanner.id}/tasks"
