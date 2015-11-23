"use strict"

LinearModel = require "backbone.linear"
async = require "async"

module.exports = class App.Models.CrashNotice extends App.Helpers.virtual_class(
  LinearModel
  App.Common.ValidationModel
)

  server: null

  # ************
  #  PUBLIC
  # ************
  send_test_messages : ->
    new Promise (resolve, reject) =>
      async.waterfall [
        (cb) =>
          unless @validate()
            cb()
        (cb) =>
          $.ajax
            contentType : "application/json"
            data     : JSON.stringify(
              LinearModel.unflatten @toJSON(), @flat_options
            )
            type     : "POST"
            url      : "#{App.Config.server}/api/systemCheck/setting/test?serverId=#{@server}"

            error : (xhr) -> cb xhr.responseText
            success : _.partial cb, null
        (resp, some..., cb) =>
          @listenTo App.Session.currentUser(),
            "message"
            _.partial cb, null, resp.data.id
        (job_id, socket_data, cb) ->
          if job_id is socket_data.data.job_id
            cb socket_data.data.data.error_message
      ], (error) =>
        @stopListening App.Session.currentUser(),
          "message"

        if error
          reject error
        else
          resolve()


  # **************
  #  BACKBONE
  # **************
  url : ->
    url = "#{App.Config.server}/api/systemCheck/setting"

    if @server
      url += "?serverId=#{@server}"

    url


  # *********************
  #  BACKBONE-LINEAR
  # *********************
  flat_options :
    delimiter : "__"

  islock: (data) ->
    data = action: data if _.isString data
    data.type = "crash_notice"
    super data

  # *************************
  #  BACKBONE-VALIDATION
  # *************************
  validation :
    "smtp_server__smtp" : [
      required: true
      msg: "settings.crash_notice.validate__server_required"
    ],
    "smtp_server__port" : [
      required: true
      msg: "settings.crash_notice.validate__port_required"
    ,
      range: [1, 65535]
      msg: "settings.crash_notice.validate__port"
    ]
    "prefix" : [
      required: false
    ,
      maxLength: 15
      msg: "settings.crash_notice.validate__prefix"
    ]
    "mailing_list" : [
      required: true
      msg: "settings.crash_notice.validate__mailing_list"
    ]

  parse: (response) ->
    response = response.data or response

    super response
