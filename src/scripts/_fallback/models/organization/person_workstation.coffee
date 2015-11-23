"use strict"

require "models/organization/contacts.coffee"

StatusesCollection =
  require "models/lists/statuses.coffee"
  .Collection

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Models.Organization ?= {}

    class App.Models.Organization.PersonWorkstation extends App.Common.ValidationModel

      # ************
      #  PUBLIC
      # ************
      addExistingGroup: (model) ->
        @get("groups").add model,
          silent: true


      # **************
      #  BACKBONE
      # **************
      defaults: ->
        SOURCE   : 'tm'

      get: (attr) ->
        unless super?
          switch attr
            when "contacts"
              @set(
                "contacts"
                new App.Models.Organization.Contacts([], type: @type)
              )
            when "groups"
              @set(
                "groups"
                new App.Models.Organization.Groups [], comparator : "NAME_PATH"
              )
            when "persons"
              if @type is "workstation"
                @set(
                  "persons"
                  new App.Models.Organization.Persons()
                )
            when "workstations"
              if @type is "person"
                @set(
                  "workstations"
                  new App.Models.Organization.Workstations()
                )
            when "status"
              @set(
                "status"
                new StatusesCollection
              )
        super

      parse: (response) ->
        resp = response.data  or  response

        if resp.contacts
          resp.contacts = new App.Models.Organization.Contacts(
            resp.contacts[..]
            isNew: -> false
            type: @type
          )

        if resp.groups
          resp.groups = new App.Models.Organization.Groups resp.groups[..], comparator : "NAME_PATH"

        if resp.status
          resp.status = (
            @get "status"
            .reset resp.status

            @get "status"
          )

        super resp



    class App.Models.Organization.PersonWorkstations extends App.Common.BackbonePagination

      # *************
      #  PRIVATE
      # *************
      _get_fetch_filter = (group_id, entity_type) ->
        obj = {}

        if (
          App.Controllers.Organization
          .groupsCollection.active_model
          .get?("GROUP_TYPE") is "adlibitum"
        )
          obj[ "SERVER_NAME" ] = group_id

        else if entity_type is "persons"
          obj[ "p2g_all.PARENT_GROUP_ID" ] = group_id

        else if entity_type is "workstations"
          obj[ "w2g_all.PARENT_GROUP_ID" ] = group_id

        if App.Controllers.Organization.groupsCollection.active_model.get?("SOURCE") is "ad"
          _.extend obj, Organization.reqres.request "get:search:filter"

        if (
          status_ids = Organization.reqres.request "get:status:filter"
          status_ids.length
        )
          obj[ "status.IDENTITY_STATUS_ID" ] = status_ids

        obj

      _get_fetch_filter_crawler = (group_id) ->
        obj = {}
        obj[ "w2g_all.PARENT_GROUP_ID" ] = group_id
        obj


      # ************
      #  PUBLIC
      # ************
      fetchGroupItems: (
        id = App.Controllers.Organization.groupsCollection.active_model.id
        options
      ) ->
        @groupId = id
        @fetch(options)

      is_all_loaded: ->
        @length is @total_count

      loadMoreItems: ->
        @fetch
          data :
            start : @length
          not_cancel_editing : true
          remove         : false

      prefetch_groups: (id) ->
        model = @get(id)
        if model.get("groups").length is 0
          model.fetch(
            data: with: "groups"
          )

      search: (query, search_filter, lazy) ->
        filter = {}

        if query and query.length
          _.extend(
            filter
            DISPLAY_NAME: "#{ query }*"
          )

        if _.isObject(search_filter)
          _.extend(
            filter
            search_filter
          )

        if not $.isEmptyObject(filter)
          @totalCount = null
          @start =
            if lazy
              @length
            else
              0
          @fetch(
            data:
              filter : filter
            remove :
              if lazy
                false
              else
                true
          )
        else
          @fetchGroupItems()


      # **************
      #  BACKBONE
      # **************
      comparator: (model) -> model.get("DISPLAY_NAME")?.toLowerCase()

      model: App.Models.Organization.PersonWorkstation


      # **********
      #  INIT
      # **********
      initialize: (models, config = {}) ->
        @module = config.module

        @limit = config.limit

        @listenTo Organization, "fetch:group:items", @fetchGroupItems

        @on "destroy", ->
          Organization.trigger "reduce:persons:workstations:count", @type

        @on "sync", (col, resp) ->
          if col instanceof Backbone.Collection
            data = {}
            data[@type] = resp.totalCount

            Organization.trigger(
              "set:persons:workstations:count"
              data
            )


      # ***************
      #  PAGINATOR
      # ***************
      paginator_core:
        url: ->
          filter = ''

          switch @type
            when "persons"
              url_entity = "ldapPerson"
            when "workstations"
              url_entity = "ldapWorkstation"

          if @groupId
            filter = _.reduce(
              if @module is "crawler"
                _get_fetch_filter_crawler @groupId
              else
                _get_fetch_filter @groupId, @type

              (result, val, key) ->
                if _.isArray val
                  for elem in val
                    result += "filter[#{key}][]=#{elem}&"

                  result
                else
                  result += "filter[#{key}]=#{val}&"

              ""
            )

          "
            #{App.Config.server}/api/#{ url_entity }?\
            #{filter}\
            limit=#{@perPage}&\
            sort[DISPLAY_NAME]=asc&\
            start=#{@currentPage * @perPage}
          "
        dataType: "json"

      paginator_ui:
        firstPage   : 0
        currentPage : 0
        perPage     : 30
