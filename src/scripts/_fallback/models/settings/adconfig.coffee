"use strict"

require "common/backbone-tree.coffee"

exports.Model = class LdapServer extends App.Common.ModelTree

  idAttribute: 'name'

  urlRoot: "#{App.Config.server}/api/adlibitum/server"

  defaults:
    enabled             : "1"
    use_global_catalog  : "1"
    global_port         : 3268
    dom_port            : 389
    page_size           : 500
    syncOptions:
      synchronize_type  : "minutes"
      MINUTES           : 15

  type: 'ldap'

  validation:
    display_name: [
      {
        required: true
        msg: 'settings.ldap_settings.ldap_name_required_validation_message'
      }
      {
        rangeLength: [1, 256]
        msg: 'settings.ldap_settings.ldap_name_length_validation_error'
      }
      {
        pattern: /^[a-zA-ZА-Яа-я0-9\u0600-\u06FF-` ёЁ\u00C0-\u017F .-]+$/ig
        msg: 'settings.ldap_settings.ldap_name_validation_message'
      }
      {
        not_unique_field: true
        msg: 'settings.ldap_settings.name_uniq_validation_error'
      }
    ]
    address: [
      {
        required: true
        msg: 'settings.ldap_settings.ldap_host_reqired_validation_message'
      }
    ]
    global_port: [
      required: (value, attr, computedState) ->
        if parseInt(computedState.server_type, 10) is 1
          return true

        return false
      msg: 'settings.ldap_settings.ldap_port_required_validation_message'
    ,
      fn: (value, attr, computedState) ->
        if parseInt(computedState.server_type, 10) is 1
          if parseInt(value, 10) < 1 or parseInt(value, 10) > 65535
            return true

        return false
      msg: 'settings.ldap_settings.ldap_port_range_validation_message'
    ]
    dom_port: [
      required: true
      msg: 'settings.ldap_settings.ldap_dom_port_required_validation_message'
    ,
      min: 1
      max: 65535
      msg: 'settings.ldap_settings.ldap_dom_port_range_validation_message'
    ]
    base: [
      {
        required: (value, attr, computedState) ->
          if parseInt(computedState.server_type, 10) is 1 and value is ''
            return true

          return false
        msg: 'settings.ldap_settings.base_required_validation_message'
      }
      {
        fn: 'base_validator'
      }
    ]
    username: [
      {
        required: true
        msg: 'settings.ldap_settings.login_required_validation_message'
      }
    ]

    'syncOptions.WEEK_TIME': [fn: 'job_validator']

    'syncOptions.DAY_TIME': [fn: 'job_validator']

    'syncOptions.HOURS': [fn: 'job_validator']

    'syncOptions.week_days': [fn: 'job_week_days_validator']

    'syncOptions.MINUTES': [fn: 'job_validator']

  typeToAttrMap:
    weekly: 'WEEK_TIME'
    daily: 'DAY_TIME'
    hours: 'HOURS'
    minutes: 'MINUTES'

  jobPeriodPatterns:
    weekly: /^\d{1,2}\:\d{2}$/
    daily: /^\d{1,2}\:\d{2}$/
    hours: /^\d{1,2}$/
    minutes: /^\d{1,2}$/


  getName: ->
    @get 'display_name'

  # Set sync period for ldap server
  #
  # @return {jqXHR} jquery promise object
  #
  setSyncPeriod: (period) ->
    $.ajax @url() + "/job",
      type: 'PUT'
      data: JSON.stringify(period)


  parseDate: (date) ->
    date = "#{date}"
    date = switch true
      when date.match(/\d{8}T\d{6}/)?
        moment([
          date.slice(0, 4), "-", date.slice(4, 6), "-",
          date.slice(6, 8), " ", date.slice(9, 11), ":", date.slice(11, 13)
        ].join '').add 3, 'h'
      when date.match(/\d+$/)?
        date = moment(parseInt date).add 3, 'h'
      else
        moment()
    date

  # Parse date from error description
  #
  # @return {Moment} moment.js date object
  #
  parseDateFromErrorMsg: ->
    try
      sign = @get('sync_description').match(/(?!\@)([^\s]+)/g)[1]
      @parseDate sign
    catch
      false

  # get description (if it exists ...)
  # and cut error and timestamp from it
  # ... else show in-progress status
  #
  getSyncStatus: ->
    if @get('sync_in_progress')
      App.t 'settings.ldap_settings.sync_in_progress'
    else
      if desc = @get 'sync_description'
        App.t "settings.ldap_settings.sync_#{if desc is 'success' then 'done' else 'failed'}",
          error: desc.replace(/[\s]*error[^\-]*\-[\s]*/, '')
      else
        App.t 'settings.ldap_settings.sync_not_started'

  # Translate last sync date from error description
  # if description contains error keyword and timestamp
  # or translate model timestamp
  #
  # @return {Moment} moment.js date object
  #
  getLastSyncDate: ->
    if @get('sync_description')?.match(/error/)
      @parseDateFromErrorMsg()
    else
      if @get('last_sync_timestamp')
        moment.utc(@get('last_sync_timestamp'), 'YYYYMMDDTHHmmss').local()
      else
        null

  # Calc next sync date
  #
  # @return [Date] date object
  #
  getNextSyncDate: ->
    date = @getLastSyncDate()
    return null unless date

    syncOptions = @get 'syncOptions'

    type = syncOptions.synchronize_type.toUpperCase()
    now  = moment()

    switch type
      when 'MINUTES'
        m = parseInt(syncOptions[type])
        date.add m, 'm'

      when 'HOURS'
        h = parseInt(syncOptions[type])
        date.add h, 'h'

      when 'DAILY', 'WEEKLY'
        # parse to array

        # hours & minutes are absolute in this case
        [_hour, _min] = syncOptions.TIME.split(":")

        passed = now.format("HH:mm") >= syncOptions.TIME

        date
          .hour parseInt(_hour)
          .minute parseInt(_min)

        # calculate the closest sync day
        if syncOptions.WEEK_TIME?
          _days = syncOptions.day_of_week.split(',')

          dayDiff = _.min _.map _days, (i) ->
            diff = parseInt(i) - now.day()
            switch true
              when diff < 0
                diff = 7 + diff
              when diff is 0
                # today
                unless passed
                  0
                else
                  7
              else
                diff
          date
            .day now.day() + dayDiff
        else
          if passed
            date.add 1, 'd'

    date


  startSync: ->
    $.ajax @url(),
      type: 'PATCH'
      data: JSON.stringify(
        ACTION: 'startSync'
        DATA:
          server_name: @get('name')
          force_full_sync: true
      ),
      success: =>
        @set 'sync_in_progress', true


  testConnection: (data) ->
    if not @isNew() and not @get 'password'
      data = _.omit data, 'password'

    $.ajax @url(),
      type: 'PATCH'
      data: JSON.stringify(
        ACTION: 'test'
        DATA: data
      )


  job_week_days_validator: (value, attr, computedState) ->
    unless computedState.enabled then return
    if computedState.syncOptions.synchronize_type is "weekly"
      unless computedState.job.day_of_week
        return App.t "settings.ldap_settings.week_days_required_validation_message"


  job_validator: (value, attr, computedState) =>
    unless computedState.enabled then return
    type = computedState.syncOptions.synchronize_type
    if attr.split('.')[1] is @typeToAttrMap[type]
      if _.isEmpty value
        App.t "settings.ldap_settings.#{type}_required_validation_message"
      else
        unless @jobPeriodPatterns[type].test value
          return App.t "settings.ldap_settings.#{type}_format_validation_message"

        if type in ['hours', 'minutes'] and value > 60 or value < 1
          return App.t "settings.ldap_settings.#{type}_format_validation_message"


  base_validator: (value, attr, computedState) ->
    # Если это сервер Active Directory
    if parseInt(computedState.server_type, 10) is 1
      regexp = /\bdc=(.*?)+/ig
    # Если это сервер Domino Directory
    else
      regexp = /[cn|c|o|ou]+=([^,]+),?/ig

    if not regexp.test(value)
      if parseInt(computedState.server_type, 10) is 1
        return App.t 'settings.ldap_settings.base_dc_ad_required_validation_message'
      else
        return App.t 'settings.ldap_settings.base_dc_dd_required_validation_message'


  parse: ->
    response = super

    if response.job
      if response.job.day_of_week is "1-7"

        if response.job.hour is '0-23'
          opts =
            synchronize_type: 'minutes'
            MINUTES: response.job.minute.split('/')[1]

        else
          if response.job.hour.indexOf('/') isnt -1
            opts =
              synchronize_type: 'hours'
              HOURS: response.job.hour.split('/')[1]

          else
            opts =
              synchronize_type: 'daily'
              DAY_TIME: "#{response.job.hour}:#{response.job.minute}"

            # for convenience
            # TODO: Ask backend developers to return time in HH:MM format or add helper
            opts.TIME = if opts.DAY_TIME.length is 4 then "0#{opts.DAY_TIME}" else opts.DAY_TIME

      else
        opts =
          synchronize_type: 'weekly'
          # Replacing week days because of day code difference on frontend and backend (1-7 from Monday - frontend, 1-7 from Sunday - backend)
          week_days: response.job.day_of_week?.split(',').map((day) -> if day is 1 then 7 else --day) or {}
          WEEK_TIME: "#{response.job.hour}:#{response.job.minute}"

        # for convenience
        opts.TIME = if opts.WEEK_TIME.length is 4 then "0#{opts.WEEK_TIME}" else opts.WEEK_TIME

      response.syncOptions = _.extend opts, response.job

    response.enabled = if response.enabled then 1 else 0
    response.use_global_catalog = if response.use_global_catalog then 1 else 0

    if response.password is null
      delete response.password

    response


exports.Collection = class LdapServers extends App.Common.CollectionTree

  model: exports.Model

  url: "#{App.Config.server}/api/adlibitum/server"

  toolbar: ->
    start_sync: (selected) ->
      selected

  config: ->
    debugLevel : 0
    extensions : []
