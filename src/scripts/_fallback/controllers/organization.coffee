"use strict"

require "models/organization/groups.coffee"
require "models/organization/persons.coffee"
require "models/organization/workstations.coffee"
require "views/organization/groups.coffee"
require "views/organization/content.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    class OrganizationController extends Marionette.Controller


      # **********
      #  INIT
      # **********
      initialize: ->
        @groupsCollection = new App.Models.Organization.Groups()
        @personsCollection = new App.Models.Organization.Persons [],
          limit : 30
        @workstationsCollection = new App.Models.Organization.Workstations [],
          limit : 30

        @listenToOnce App.Configuration, "configuration:rollback", ->
          App.vent.trigger "reload:module"

        Organization.reqres.setHandler "drill:down:data", ->
          null


      # ************
      #  PUBLIC
      # ************
      index: (identity) ->
        @groupsView = new App.Views.Organization.Groups(
          collection     : @groupsCollection
        )

        @contentView = new App.Views.Organization.Content
          personsCollection: @personsCollection
          workstationsCollection: @workstationsCollection
          config:
            initialTab: identity?.type ? 'persons'

        # Если передали данные
        if identity and (identity.group_id or identity.identity_id)
          # Ждем полной загрузки дерева
          @groupsView.on 'treeview:postinit', =>
            # Если задана группа - сначало находим ее
            if identity.group_id
              collection = new App.Models.Organization.Groups()
              group = collection.fetchOne identity.group_id, {}, =>
                @groupsView.select path: group.get('ID_PATH'), (node) =>
                  # Душим запрос пораждаемый выбором группы
                  # можно было бы делать silent выделение, но
                  # к сожалению выбор группы необходим
                  $.xhrPool.abortAll()

                  if identity.identity_id
                    switch identity.type
                      when 'persons'
                        @personsCollection.search null,
                          PERSON_ID: identity.identity_id
                      when 'workstations'
                        @workstationsCollection.search null,
                          WORKSTATION_ID: identity.identity_id
                      else
                        debug "Error. Bad identity type: #{identity.type}"
                  else
                    @groupsView.triggerMethod "treeview:select", node

                , true
            else
              switch identity.type
                when 'persons'
                  @personsCollection.search null,
                    PERSON_ID: identity.identity_id
                when 'workstations'
                  @workstationsCollection.search null,
                    WORKSTATION_ID: identity.identity_id
                else
                  debug "Error. Bad identity type: #{identity.type}"
        else if identity and identity.status
          # Ждем полной загрузки дерева
          @groupsView.on 'treeview:postinit', =>
            data = {
              "status.IDENTITY_STATUS_ID": identity.status
            }

            switch identity.type
              when "persons", "workstations"
                prefix = if identity.type is "persons"  then "p2s" else "w2s"

                if identity.STATUS_FROM?
                  if not data["#{ prefix }.CHANGE_DATE"]
                    data["#{ prefix }.CHANGE_DATE"] = {}
                  data["#{ prefix }.CHANGE_DATE"]["FROM"] = identity.STATUS_FROM

                if identity.STATUS_TO?
                  if not data["#{ prefix }.CHANGE_DATE"]
                    data["#{ prefix }.CHANGE_DATE"] = {}
                  data["#{ prefix }.CHANGE_DATE"]["TO"] = identity.STATUS_TO

                Organization.reqres.setHandler "drill:down:data", ->
                  data

                (
                  if identity.type is "persons"
                    @personsCollection
                  else
                    @workstationsCollection
                )
                .search null, data
              else
                debug "Error. Bad identity type: #{identity.type}"
        else
          # По умолчанию выделяем группу tmRoot
          @groupsView.on 'treeview:postinit', (root) ->
            if _node = root.getNodeByKey(App.Views.Organization.Groups::tmRoot)
              _node.setActive()



    Organization.addInitializer ->
      # Стартуем контроллер конфигурации
      App.Configuration.show()
      App.Controllers.Organization = new OrganizationController()

    Organization.addFinalizer ->
      App.Controllers.Organization.destroy()
      App.Configuration.hide()
