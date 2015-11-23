"use strict"

async = require "async"
co = require "co"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Models.Organization ?= {}

    class App.Models.Organization.Group extends Backbone.Model

      # **************
      #  BACKBONE
      # **************
      defaults:
        IS_VISIBLE: 1

      idAttribute: "GROUP_ID"

      parse: (response) ->
        resp = response.data or response

        if resp.contacts
          resp.contacts = new App.Models.Organization.Contacts resp.contacts[..],
            isNew : -> false
            type  : @type

        super resp

      urlRoot : "#{App.Config.server}/api/ldapGroup/"


      # **********
      #  INIT
      # **********
      initialize: ->
        @display_attr = 'DISPLAY_NAME'

        @on "reduce:persons:workstations:count", (type) ->
          @set(
            "#{type}Count"
            @get("#{type}Count") - 1
            silent: if @ is @collection.active_model then false else true
          )

        @on "increase:persons:workstations:count", (type) ->
          @set(
            "#{type}Count"
            parseInt(@get("#{type}Count")) + 1
            silent: if @ is @collection.active_model then false else true
          )


      # ************
      #  PUBLIC
      # ************
      detailed_fetch : ->
        @fetch
          data  :
            with :
              0   : "personsCount"
              1   : "workstationsCount"
              2   : "contacts"
              parents : ["NAME_PATH"]
              childs  : ["NAME_PATH"]
          silent  : true
          success : (model) ->
            Organization.trigger "set:persons:workstations:count",
              persons    : model.get "personsCount"
              workstations : model.get "workstationsCount"

      get_ldap_sync : ->
        if @get( "GROUP_TYPE" ) is "adRoot"
          state   :
            if @get( "SYNC_IN_PROGRESS" )
              "progress"
            else if @get( "SYNC_DESCRIPTION" ) is ""
              "not_performing"
            else if @get( "SYNC_DESCRIPTION" ) is "success"
              "success"
            else
              "error"
          timestamp :
            if (
              moment.utc @get( "LAST_SYNC_TIMESTAMP" ), "DD-MM-YYYY HH:mm:ss.SSS"
              .unix() is 0
            )
              false
            else
              App.Helpers.show_datetime @get("LAST_SYNC_TIMESTAMP"),
                input_mask: "DD-MM-YYYY HH:mm:ss.SSS"

      get_parent_id : ->
        _ @get("ID_PATH").split "\\"
        .take-right 2
        .first()

      transfer_to : (model_destination) -> co =>
        yield new Promise (resolve) =>
          async.each [
            @
            model_destination

          ], (group_model, done) ->
            if group_model.get "childs"
              done()
            else
              group_model.detailed_fetch()
              .success -> done()
          ,
            resolve

        @save
          parents : do =>
            parents = _.clone @get "parents"
            if @get("SOURCE") is "tm"
              _.remove parents, GROUP_ID : @get_parent_id()

            parents.push GROUP_ID : model_destination.id
            parents
        ,
          wait  : true
          silent  : true
          success : (model) ->
            model.set
              ID_PATH : "#{ model_destination.get "ID_PATH" }\\#{ model.id }"
            model.trigger "change:parents", model

      type: "group"


    class App.Models.Organization.Groups extends Backbone.Collection

      # ************
      #  PUBLIC
      # ************
      fetchOne: (id, options, success) ->
        result = @get(id)
        if (typeof result isnt 'undefined')
          if success
            success.apply(@, [result])
          return result

        where = {}
        where[@model.prototype.idAttribute] = id
        model = new @model(where)
        @add(model, options)
        model.fetch(_.extend options, { success: (model, response, options) =>
          if success
            success.apply(@, [model])
        })
        return model


      # **************
      #  BACKBONE
      # **************
      model: App.Models.Organization.Group

      url: "#{App.Config.server}/api/ldapGroup/"


      # **********
      #  INIT
      # **********
      initialize: ->

        @listenTo Organization, "reduce:persons:workstations:count", (type) ->
          if(
            @active_model?  and
            @active_model.id is App.Controllers.Organization.groupsCollection.active_model.id
          )
            @active_model.set(
              "#{type}Count",
              @active_model.get("#{type}Count") - 1
            )


        @listenTo Organization, "increase:persons:workstations:count", (type) ->
          if(
            @active_model?  and
            @active_model.id is App.Controllers.Organization.groupsCollection.active_model.id
          )
            @active_model.set(
              "#{type}Count",
              parseInt(@active_model.get("#{type}Count")) + 1
            )

        @on "change:personsCount change:workstationsCount", (model) ->
          Organization.trigger "set:persons:workstations:count",
            persons: model.get "personsCount"
            workstations: model.get "workstationsCount"
