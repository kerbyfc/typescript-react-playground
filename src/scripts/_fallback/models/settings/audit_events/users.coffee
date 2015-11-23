"use strict"

Users = require "models/settings/user.coffee"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Models.AuditEvents ?= {}

    class App.Models.AuditEvents.Users extends Users.Collection

      # *************
      #  PRIVATE
      # *************
      _get_user_name_by_id = (id, self = @) ->
        model = self.get id

        if model
          name = model.get "DISPLAY_NAME"
          login = model.get "USERNAME"

          "#{name} (#{login})"
        else
          App.t "global.unknown"


      # *************
      #  PUBLIC
      # *************
      add_filter_all_users : ->
        @add
          DISPLAY_NAME : App.t "global.all"
          USER_ID    : "<all>"
        ,
          at     : 0
          silent : true


      # ************************
      #  BACKBONE-PAGINATOR
      # ************************
      paginator_ui:
        firstPage : 0
        currentPage : 0
        perPage   : 1000


      # **************
      #  BACKBONE
      # **************
      comparator : ->
        formatted_names =
          _ arguments
          .map (model) => _get_user_name_by_id model.id, @
          .invoke String::toLowerCase
          .value()

        if formatted_names[0] < formatted_names[1]
          -1
        else
          1


      # **********
      #  INIT
      # **********
      initialize : ->
        AuditEvents.reqres.setHandler "get:user:name:by:id",
          _get_user_name_by_id
          @
