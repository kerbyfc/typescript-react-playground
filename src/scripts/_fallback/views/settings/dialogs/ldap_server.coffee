"use strict"

exports.ADServerEmptyDialog = class ADServerEmptyDialog extends Marionette.ItemView

  className: 'empty-block__message'

  template: "settings/ldap_servers_empty"

exports.ADServerInfoDialog = class ADServerInfoDialog extends Marionette.ItemView

  className: 'content'

  template: "settings/dialogs/ldap_server_info"

  events:
    "click [data-action='check']" : "testConnection"

  ui:
    sync_status: '#sync_status'
    last_sync:   '#last_sync'
    next_sync:   '#next_sync'

  initialize: ->
    @listenTo App.vent, "user:destroy", @_resetTimer

  testConnection: (e) ->
    e?.preventDefault()

    @model.testConnection @model.toJSON()
    .done ->
      App.Notifier.showSuccess
        title: App.t 'settings.ldap'
        text: App.t 'settings.ldap_settings.check_done'
        hide: true
    .fail ->
      App.Notifier.showError
        title: App.t 'settings.ldap'
        text: App.t 'settings.ldap_settings.check_failed'
        hide: true


  templateHelpers: ->
    sync_status: @model.getSyncStatus()
    last_sync: =>
      last_sync = @model.getLastSyncDate()
      if last_sync
        "#{last_sync.calendar()} (#{last_sync.fromNow()})"
      else
        App.t 'settings.ldap_settings.sync_not_started'

    next_sync: =>
      next_sync = @model.getNextSyncDate()
      if next_sync
        "#{next_sync.calendar()} (#{next_sync.fromNow()})"
      else
        App.t 'settings.ldap_settings.sync_not_started'


  onShow: ->
    @_resetTimer()
    @timer = setInterval @_checkSyncStatus, 5000


  onDestroy: ->
    @_resetTimer()


  _checkSyncStatus: =>
    toolbarStateEvent = if @model.get('sync_in_progress') then 'disable:toolbar' else 'update:toolbar'
    App.vent.trigger(toolbarStateEvent)

    @model.fetch
      disableNProgress: true
      success: =>
        lastSync = @model.getLastSyncDate()
        nextSync = @model.getNextSyncDate()

        @ui.sync_status.html(@model.getSyncStatus())
        if lastSync
          @ui.last_sync.html "#{lastSync.calendar()} (#{lastSync.fromNow()})"
          @ui.next_sync.html "#{nextSync.calendar()} (#{nextSync.fromNow()})"


  _resetTimer: =>
    if @timer
      clearInterval(@timer)
      @timer = null


exports.ADServerDialog = class ADServerDialog extends Marionette.ItemView

  className: "content"

  template: "settings/dialogs/ldap_server"

  events:
    "click [data-action='save']"   : "save"
    "click [data-action='check']"  : "testConnection"
    "click [data-action='cancel']" : "closeAdServer"

  ui:
    name                   : '[name=display_name]'
    minutes_schedule       : '[data-schedule="minutes"]'
    use_global_catalog     : '#use_global_catalog'
    global_port            : '#global_port'
    synchronization_params : '#synchronization_params'


  behaviors: ->
    model_data = @options.model.toJSON()

    if @options.model.isNew()
      model_data.MINUTES = 15
    else
      model_data.password = '!!password_not_changed!!'

    Form:
      listen : @options.model
      syphon : model_data

  closeAdServer: (e) ->
    e.preventDefault()
    @options.callback(true) if @options.callback

  testConnection: (e) ->
    e?.preventDefault()

    data = Backbone.Syphon.serialize @

    settings =
      display_name: data.display_name
      address: data.address
      server_type: data.server_type
      dom_port: data.dom_port
      username: data.username
      password: data.password
      base: data.base
      page_size: 500

    if parseInt(data.server_type, 10) is 1
      settings.global_port = data.global_port
      settings.use_global_catalog = data.use_global_catalog

    @model.testConnection settings
    .done ->
      App.Notifier.showSuccess
        title: App.t 'settings.ldap'
        text: App.t 'settings.ldap_settings.check_done'
        hide: true
    .fail ->
      App.Notifier.showError
        title: App.t 'settings.ldap'
        text: App.t 'settings.ldap_settings.check_failed'
        hide: true

  save: (e) ->
    e.preventDefault()

    # Собираем данные с контролов
    data = @getData()

    if data.password is '!!password_not_changed!!'
      data.password = ''

    #TODO: Добавить вызов preValidate

    period = switch data.syncOptions.synchronize_type
      when 'minutes'
        minute      : "0-59/#{data.syncOptions.MINUTES}"
        hour        : "0-23"
        day_of_month: "1-31"
        month       : "1-12"
        day_of_week : "1-7"
      when 'hours'
        minute      : moment().format('mm')
        hour        : "1-23/#{data.syncOptions.HOURS}"
        day_of_month: "1-31"
        month       : "1-12"
        day_of_week : "1-7"
      when 'daily'
        minute      : data.syncOptions.DAY_TIME.split(':')[1]
        hour        : data.syncOptions.DAY_TIME.split(':')[0]
        day_of_month: ""
        month       : "1-12"
        day_of_week : "1-7"
      when 'weekly'
        minute      : data.syncOptions.WEEK_TIME.split(':')[1]
        hour        : data.syncOptions.WEEK_TIME.split(':')[0]
        day_of_month: ""
        month       : ""
        # Replacing week days because of day code difference on frontend and backend
        # (1-7 from Monday - frontend, 1-7 from Sunday - backend)
        day_of_week : data.syncOptions.week_days?.map (day) ->
          if day is 7 then 1 else ++day
        .join(",")
      else ""

    data.job = period

    data = _.pick data, [
      'display_name'
      'address'
      'global_port'
      'dom_port'
      'enabled'
      'use_global_catalog'
      'base'
      'page_size'
      'server_type'
      'username'
      'password'
      'job'
      'syncOptions'
    ]

    data.server_type = parseInt(data.server_type, 10)

    if data.server_type is 2
      @model.unset 'use_global_catalog'
      @model.unset 'global_port'

      delete data['use_global_catalog']
      delete data['global_port']

    @options.callback(false, data) if @options.callback

  onRender: ->
    model_data = @model.toJSON()

    # Скрываем все возможные варианты выбора расписания
    for schedule_type in ['minutes', 'hours', 'daily', 'weekly']
      @$("[data-schedule=#{schedule_type}]").hide()

    if @model.isNew()
      @ui.minutes_schedule.css "display", "flex"
    else
      @$("[data-schedule=#{model_data.syncOptions.synchronize_type}]").css "display", "flex"

    # Если это Lotus сервер, то скрываем лишние параметры синхронизации
    if parseInt(@model.get('server_type'), 10) is 2
      @ui.use_global_catalog.hide()
      @ui.global_port.hide()

    @ui.synchronization_params.hide() if not model_data.enabled

    @$('[name="server_type"]').select2
      minimumResultsForSearch: 100
    .on 'change', (e) =>
      if parseInt(e.val, 10) is 1
        @ui.use_global_catalog.show()
        @ui.global_port.show()
        @$('[name="USE_GLOBAL_CATALOG"]').val('')
      else
        @ui.use_global_catalog.hide()
        @ui.global_port.hide()
        @$('[name="USE_GLOBAL_CATALOG"]').val('')

    @$('[name="syncOptions[synchronize_type]"]').select2
      minimumResultsForSearch: 100
    .on 'change', (e) =>
      for schedule_type in ['minutes', 'hours', 'daily', 'weekly']
        @$("[data-schedule=#{schedule_type}]").hide()

      @$("[data-schedule=#{e.val}]").show()

    @$('[name="enabled"]').on "change", (e) =>
      if $(e.currentTarget).is(":checked")
        @ui.synchronization_params.show()
      else
        @ui.synchronization_params.hide()
