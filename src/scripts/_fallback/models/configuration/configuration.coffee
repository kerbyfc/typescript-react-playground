"use strict"

require "pushstream"

App.module "Configuration",
  startWithParent: false
  define: (Configuration, App, Backbone, Marionette, $) ->

    App.Models.Configuration ?= {}

    class App.Models.Configuration.Configuration extends App.Common.ValidationModel

      urlRoot: "#{App.Config.server}/api/config"

      validation:
        NOTE: [
          {
            rangeLength: [0, 1000]
            msg: App.t 'configuration.configuration_note_length_validation_error'
          }
          {
            required: false
          }
        ]

      initialize: ->
        @pushstream = new PushStream
          host: App.Config.server.replace /(http:\/\/|https:\/\/)/, ""
          modes: "websocket|stream|longpolling"
          useSSL: location.protocol.match(/^https/)? or App.Config.server.match(/^https/)?
          urlPrefixWebsocket : "/api/notify/listen"

        @pushstream.addChannel "service_config"

      parse: (response) ->
        response = response.data or response
        response[0]

      _catchCometMessage: (e) =>
        @set $.parseJSON(e.data).data

      ##########################################################################
      # PUBLIC
      startListener: ->
        @pushstream.onstatuschange = (e) =>
          if e is PushStream.OPEN
            @pushstream.wrapper.connection.onmessage = @_catchCometMessage

            @pushstream.wrapper.connection.onerror = (e)->
              debug "Catch error from configuration socket."

        @pushstream.connect()

      stopListener: ->
        @pushstream.disconnect()

      isLocked: ->
        if(
          parseInt(@get("STATUS"), 10) is 1 and
          parseInt(@get('USER_ID'), 10) isnt parseInt(App.Session.currentUser().get('USER_ID'), 10)
        )
          return true
        else
          return false

      isEdited: ->
        if(
          parseInt(@get("STATUS"), 10) is 1 and
          parseInt(@get('USER_ID'), 10) is parseInt(App.Session.currentUser().get('USER_ID'), 10)
        )
          return true
        else
          return false

      publishPolicy: ->
        $.ajax
          url: "#{App.Config.server}/api/policy/publish"
