"use strict"

BaseCrawlerModel = require "models/crawler/base.coffee"

exports.Model = class Scanner extends App.Helpers.virtual_class(
  BaseCrawlerModel
  App.Common.ValidationModel
)

  type: "agent"

  islock: Backbone.Model::islock

  validate: (value) ->
    err = super(value)

    parseUrl = value.ExpressdUri.Value.replace("xml://", "").split(':')

    err ?= {}

    if parseUrl[0] is ""
      err["ExpressdHost"] = App.t "crawler.scanner_details_server_address_required_validation_error"

    if parseUrl[1] is ""
      err["ExpressdPort"] = App.t "crawler.scanner_detaild_port_required_error"

    if not App.Helpers.patterns.dns.test parseUrl[0]
      if not App.Helpers.patterns.ip.test parseUrl[0]
        err["ExpressdHost"] = App.t "crawler.scanner_details_address_invalid"

    unless /^\d+$/.test parseUrl[1]
      err["ExpressdPort"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(parseUrl[1], 10) < 1024 or parseInt(parseUrl[1], 10) > 65535
      err["ExpressdPort"] = App.t "crawler.scanner_details_port_value_error"

    unless value.TasksTBFSpeed.Value
      err["TasksTBFSpeed[Value]"] = App.t "crawler.scanner_scan_speed_required_validation_error"

    unless /^\d+$/.test value.TasksTBFSpeed.Value
      err["TasksTBFSpeed[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.TasksTBFSpeed.Value, 10) < 0
      err["TasksTBFSpeed[Value]"] = App.t "crawler.scanner_details_number_invalid"

    unless value.SendManagerTBFSpeed.Value
      err["SendManagerTBFSpeed[Value]"] = App.t "crawler.scanner_send_speed_required_validation_error"

    unless /^\d+$/.test value.SendManagerTBFSpeed.Value
      err["SendManagerTBFSpeed[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.SendManagerTBFSpeed.Value, 10) < 0
      err["SendManagerTBFSpeed[Value]"] = App.t "crawler.scanner_details_number_invalid"

    unless value.QueueSizeLimit.Value
      err["QueueSizeLimit[Value]"] = App.t "crawler.scanner_details_queue_required_validation_error"

    unless /^\d+$/.test value.QueueSizeLimit.Value
      err["QueueSizeLimit[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.QueueSizeLimit.Value, 10) < 1024 or parseInt(value.QueueSizeLimit.Value, 10) > 1024 * 1024
      err["QueueSizeLimit[Value]"] = App.t "crawler.scanner_details_file_queue_validation_error"

    unless value.OutFileQueueCheckInterval.Value
      err["OutFileQueueCheckInterval[Value]"] = App.t "crawler.scanner_details_queue_interval_required_error"

    unless /^\d+$/.test value.OutFileQueueCheckInterval.Value
      err["OutFileQueueCheckInterval[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.OutFileQueueCheckInterval.Value, 10) <= 0
      err["OutFileQueueCheckInterval[Value]"] = App.t "crawler.scanner_details_number_invalid"

    unless value.ExpressdConnectionLimit.Value
      err["ExpressdConnectionLimit[Value]"] = App.t "crawler.scanner_details_connections_required_validation_error"

    unless /^\d+$/.test value.ExpressdConnectionLimit.Value
      err["ExpressdConnectionLimit[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.ExpressdConnectionLimit.Value, 10) < 1 or parseInt(value.ExpressdConnectionLimit.Value, 10) > 8
      err["ExpressdConnectionLimit[Value]"] = App.t "crawler.scanner_details_number_connect_invalid"

    unless value.ExpressdTcpWaitRetry.Value
      err["ExpressdTcpWaitRetry[Value]"] = App.t "crawler.scanner_details_conn_retry_required_validation_error"

    unless /^\d+$/.test value.ExpressdTcpWaitRetry.Value
      err["ExpressdTcpWaitRetry[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if parseInt(value.ExpressdTcpWaitRetry.Value, 10) <= 0
      err["ExpressdTcpWaitRetry[Value]"] = App.t "crawler.scanner_details_number_invalid"

    if _.isEmpty err then null else err

  validation:
    name: [
      required  : true
      msg       : "crawler.scaner_name_required_validation_error"
    ,
      maxLength : 256
      msg       : "scanner.scanner_name_length_validation_error"
    ,
      fn: (value) ->
        pattern = ///
          [
            а-я
            ё
            a-z
            0-9
            . , - _ : ; z( )
            \s
          ]+
        ///i

        unless pattern.test value
          App.t 'crawler.scanner_name_format_validation_error'
    ]

  url: ->
    "#{super}/configuration"

  urlRoot: "#{App.Config.server}/api/crawler/scanner"

  # TODO: Выяснить у Бори зачем нужна и почему не работатет
  getStatus: ->
    $.ajax
      url : "#{@urlRoot}/#{@id}/status"


exports.Collection = class ScannerCollection extends Backbone.Collection

  model: exports.Model

  url: "#{App.Config.server}/api/crawler/scanner"

  _ScannerConfigUpdated: (id, data) ->

    model = @get(id)

    return unless model

    model.set model.parse(data)

    #TODO: Зачем нужна эта нотификация?
    App.Notifier.showWarning
      text : App.t 'crawler.scanner_edited',
        name: model.get("name")

  _ScannerSignedOut: (id) ->

    model = @get(id)

    return unless model

    model.set "online", "false"

    #TODO: Зачем нужна эта нотификация?
    App.Notifier.showWarning
      text : App.t 'crawler.scanner_signed_out',
        name: model.get("name")

  _ScannerSignedIn: (id) ->
    model = @get(id)

    return unless model

    model.set "online", "true"

    #TODO: Зачем нужна эта нотификация?
    App.Notifier.showWarning
      text : App.t 'crawler.scanner_signed_in',
        name: model.get("name")

  _ScannerUnlocked: (id) ->
    model = @get(id)

    return unless model

    model.set "locked", "false"

    #TODO: Зачем нужна эта нотификация?
    App.Notifier.showWarning
      text : App.t 'crawler.scanner_unlocked',
        name: model.get("name")

  _ScannerLocked: (id, data) ->
    model = @get(id)

    return unless model

    model.set
      locked : "true"
      owner  : data

    #TODO: Зачем нужна эта нотификация?
    App.Notifier.showWarning
      text  : App.t 'crawler.scanner_locked',
        name: model.get("name")

  initialize: ->
    @listenTo @, "ScannerConfigUpdated", @_ScannerConfigUpdated
    @listenTo @, "ScannerSignedOut", @_ScannerSignedOut
    @listenTo @, "ScannerSignedIn", @_ScannerSignedIn
    @listenTo @, "ScannerUnlocked", @_ScannerUnlocked
    @listenTo @, "ScannerLocked", @_ScannerLocked
