"use strict"

async = require "async"
helpers = require "common/helpers.coffee"
style = require "common/style.coffee"

require "models/settings/audit_events/audit_events.coffee"
require "models/settings/audit_events/users.coffee"
require "models/settings/adconfig.coffee"
NetworkSettings = require "models/settings/setup/network.coffee"
require "models/settings/user.coffee"
Services = require "models/settings/services.coffee"
AgentServers = require "models/settings/agent_servers.coffee"
CrashNotice = require "models/settings/crash_notice.coffee"

Access =
  Users: require "models/settings/user.coffee"
  Scopes: require "models/settings/scope.coffee"
  Roles: require "models/settings/role.coffee"

AccessViews =
  Users: require "views/settings/users.coffee"
  Scopes: require "views/settings/scopes.coffee"
  Roles: require "views/settings/roles.coffee"

require "views/settings/audit_events/content.coffee"
require "views/settings/audit_events/filters.coffee"

IntegrityFilesView = require "views/settings/integrity_monitoring/files.coffee"
IntegrityFiles = require "models/settings/integrity_monitoring/files.coffee"
IntegrityJobs = require "models/settings/integrity_monitoring/jobs.coffee"
IntegrityJobSchedule = require "models/settings/integrity_monitoring/job_schedule.coffee"

require "views/settings/users_and_roles_content.coffee"

SystemCheck             = require "models/settings/system_check.coffee"
SystemCheckServerView   = require "views/settings/dialogs/system_check_server.coffee"
PluginsCollection       = require "models/settings/plugins/plugins.coffee"
AddPluginModel          = require "models/settings/plugins/add_plugin.coffee"

Licenses                = require "models/settings/licenses.coffee"

LicenseViews            = require "views/settings/licenses.coffee"
LicenseImport           = require "views/settings/dialogs/license_import.coffee"

SystemCheckServers      = require "models/settings/system_check_servers.coffee"
SystemCheckServersView  = require "views/settings/system_check_servers_list.coffee"
LdapServers             = require "models/settings/adconfig.coffee"
ADServer                = require "views/settings/dialogs/ldap_server.coffee"
LdapServersList         = require "views/settings/ldap_servers_list.coffee"
SystemCheckView         = require "views/settings/system_check.coffee"
ServicesView            = require "views/settings/services.coffee"
require "views/settings/setup/network.coffee"
UpdatePage              = require "views/settings/update/update_page.coffee"
PluginsListView         = require "views/settings/plugins/plugins_list.coffee"
PluginsAddView          = require "views/settings/plugins/add_plugin.coffee"
PluginInfo              = require "views/settings/plugins/plugin_info.coffee"
TokensView              = require "views/settings/plugins/tokens.coffee"

ServicesServersView = require "views/settings/services_servers_list.coffee"

App.module "Settings",
  startWithParent: false
  define: (Settings, App, Backbone, Marionette, $) ->

    class SettingsController extends Marionette.Controller

      system_check: ->
        system_check_servers = new SystemCheckServers.Collection
        system_check = new SystemCheck.Collection

        systemCheckServersList = new SystemCheckServersView
          collection        : system_check_servers
          resize_container  : $ App.Layouts.Application.sidebar.el

        @listenTo system_check, 'refresh', ->
          system_check.fetch
            reset: true
            wait: true
            error: ->
              App.Notifier.showError
                title: App.t 'settings.healthcheck_tab'
                text: App.t 'settings.healthcheck.refresh_status_failed'
                hide: true

        @listenTo system_check_servers, 'select', (selected) ->
          if selected
            system_check.server = selected.id
            notification_settings = new CrashNotice
            notification_settings.server = selected.id

            $.when(
              system_check.fetch(wait: true, reset: true),
              notification_settings.fetch()
            ).then (monitoring, settings) ->
              sensorsList = new SystemCheckView
                collection: system_check
                server_name: selected.get 'name'
                settings: notification_settings

              sensorsList.on 'refresh_sensors', ->
                system_check.refresh().then(
                  ->
                    App.Notifier.showSuccess
                      title: App.t('settings.healthcheck_tab'),
                      text: App.t 'settings.healthcheck.refresh_status_success'
                      hide: true
                  (error) ->
                    if error.responseText isnt 'Refresh sensors job already exists.'
                      App.Notifier.showError
                        title: App.t 'settings.healthcheck_tab'
                        text: App.t 'settings.healthcheck.refresh_status_failed'
                        hide: true
                )

              sensorsList.on 'edit_settings', ->
                App.modal.show new SystemCheckServerView
                  server_name : selected.get 'name'
                  model       : notification_settings
                  title       : App.t 'settings.healthcheck.server_settings'
                  callback: (data) ->
                    notification_settings.save(data).then?(
                      ->
                        App.modal.empty()

                        App.Notifier.showSuccess
                          title: App.t 'settings.healthcheck_tab'
                          text: App.t "settings.crash_notice.notify__save_success"
                          hide: true
                      ,
                        (xhr, type, statusText) ->
                          App.Notifier.showError
                            title: App.t 'settings.healthcheck_tab'
                            text: "#{App.t('settings.crash_notice.notify__save_fail')}:\n #{statusText}"
                            hide: true
                      )

              App.Layouts.Application.content.show sensorsList

            , (error) ->
              App.Notifier.showError
                title: App.t 'settings.healthcheck_tab'
                text: App.t 'settings.healthcheck.refresh_status_failed'
                hide: true

        App.Layouts.Application.sidebar.show systemCheckServersList

        system_check_servers.fetch
          wait: true
          reset: true
          success : ->
            first_server = system_check_servers.at 0

            systemCheckServersList.select first_server, true

            systemCheckServersList.trigger "select", first_server, first_server.id

          error: (collection, resp, options) ->
            App.Notifier.showError
              title: App.t 'settings.healthcheck_tab'
              text: App.t 'settings.healthcheck.refresh_status_failed'
              hide: true

      license: (id) ->
        licenses = App.LicenseManager.getAllLicenses()

        licenseList = new LicenseViews.List
          collection     : licenses
          resize_container : $ App.Layouts.Application.sidebar.el


        @listenTo licenseList, 'create', ->
          App.modal.show new App.Views.Licenses.LicenseImportDialog
            title: App.t 'settings.license.license_import_dialog_title'
            collection: licenses
            callback: (model) ->
              licenseList.select model, true

              App.Helpers.confirm
                title: App.t 'settings.license.license_import_dialog_title'
                data: App.t 'settings.license.license_refresh_dialog_question'
                accept: ->
                  window.location.reload()

        @listenTo licenseList, 'request_license', ->
          window.location.href = licenseList.fill_email()

        @listenTo licenses, 'destroy', ->
          App.Helpers.confirm
            title: App.t 'settings.license.license_import_dialog_title'
            data: App.t 'settings.license.license_refresh_dialog_question'
            accept: ->
              window.location.reload()

        @listenTo licenses, 'select', (selected) ->
          if selected
            App.Layouts.Application.content.show new LicenseViews.License
              model: selected
          else
            if licenses.length
              App.Layouts.Application.content.show new LicenseViews.EmptyLicense
            else
              App.Layouts.Application.content.show new LicenseViews.EmptyList

        App.Layouts.Application.sidebar.show licenseList

        licenses.fetch
          reset : true
          wait  : true
          success : ->
            if licenses.length
              if id
                license = licenses.get id
              else
                license = licenses.at(0)

              licenseList.select license, true

              licenseList.trigger "select", license, license.id
            else
              App.Layouts.Application.content.show new LicenseViews.EmptyList
          error: ->
            App.Notifier.showError
              title: App.t 'settings.licenses'
              text: App.t 'settings.license.license_service_unavailable',
              hide: true
            App.Layouts.Application.content.show new LicenseViews.EmptyList

      users_and_roles: ->
        parseError = (xhr, data) ->
          response = $.parseJSON(xhr.responseText)
          keys = _.keys response

          for key in keys
            errors = response[key]

            switch key
              when 'USERNAME'
                if 'not_unique_field' in errors
                  error = App.t 'lists.tags.tag_contstraint_violation_error',
                    name: data.DISPLAY_NAME
              else error = App.t 'global.undefined_error'

          return error

        tree = new App.Views.Settings.UsersAndRolesContent
          container : ".tree_view"

        tree.onNodeActivate = (node) ->
          cls = node.key.charAt(0).toUpperCase() + node.key.slice(1)

          content = new AccessViews[cls]
            collection: new Access[cls].Collection

          @listenTo content, 'edit:inline', (item, field, value, callback) ->
            data = {}
            data[field] = value

            item.save data,
              wait: true
              error: (model, xhr) ->
                callback(parseError(xhr, data))

          App.Layouts.Application.content.show content

        App.Layouts.Application.sidebar.show tree

      ldap: ->
        servers_collection = new LdapServers.Collection

        serverListView = new LdapServersList
          collection: servers_collection
          resize_container : $ App.Layouts.Application.sidebar.el

        startSync = (selected) ->
          selected.startSync()
          .done ->
            App.Notifier.showSuccess
              title: App.t 'settings.ldap'
              text: App.t 'settings.ldap_settings.sync_action_success',
                server: selected.get 'display_name'
              hide: true
          .fail ->
            App.Notifier.showError
              title: App.t 'settings.ldap'
              text: App.t 'settings.ldap_settings.sync_action_failed',
                server: selected.get 'display_name'
              hide: true

        @listenTo servers_collection, 'select', (selected) ->
          if selected
            model = servers_collection.get selected

            App.Layouts.Application.content.show new ADServer.ADServerInfoDialog
              model: model
          else
            App.Layouts.Application.content.show new ADServer.ADServerEmptyDialog

        @listenTo serverListView, 'start_sync', ->
          selected = servers_collection.get serverListView.getActiveNode()?.key

          startSync(selected) if selected

        @listenTo serverListView, 'edit', ->
          selected = servers_collection.get serverListView.getActiveNode()?.key

          serverListView.trigger 'disable:toolbar'
          serverListView.edit = true

          App.Layouts.Application.content.show new ADServer.ADServerDialog
            model: selected
            disabled: false
            callback: (cancel, data) ->
              if cancel
                App.Layouts.Application.content.show new ADServer.ADServerInfoDialog
                  model: selected

                serverListView.edit = false
                serverListView.trigger 'update:toolbar'
              else
                selected.save data,
                  wait: true
                  success: ->
                    App.Layouts.Application.content.show new ADServer.ADServerInfoDialog
                      model: selected

                    serverListView.edit = false
                    serverListView.trigger 'update:toolbar'

                    startSync(selected) if selected.get 'enabled'
                  error: ->
                    App.Notifier.showError
                      title : App.t 'settings.ldap'
                      text  : App.t 'settings.ldap_settings.ad_server_delete_error'
                      hide  : true

        @listenTo serverListView, 'create', ->
          selected = servers_collection.get serverListView.getActiveNode()?.key
          model = new servers_collection.model()

          serverListView.trigger 'disable:toolbar'
          serverListView.edit = true

          App.Layouts.Application.content.show new ADServer.ADServerDialog
            model: model
            callback: (cancel, data) ->
              if cancel
                if selected
                  App.Layouts.Application.content.show new ADServer.ADServerInfoDialog
                    model: selected
                else
                  App.Layouts.Application.content.show new ADServer.ADServerEmptyDialog

                serverListView.edit = false
                serverListView.trigger 'update:toolbar'
              else
                model.save data,
                  wait: true,
                  success: (model, collection, options) ->
                    servers_collection.add model

                    serverListView.edit = false
                    serverListView.trigger 'update:toolbar'

                    startSync(model) if model.get 'enabled'

                  error: (model, xhr, options) ->
                    response = $.parseJSON(xhr.responseText)

                    unless 'display_name' of response
                      App.Notifier.showError
                        title: App.t 'settings.ldap'
                        text: response
                        hide: true

        App.Layouts.Application.sidebar.show serverListView
        App.Layouts.Application.content.show new ADServer.ADServerEmptyDialog

        servers_collection.sortRule = sort:
          'display_name': 'ASC'

        servers_collection.fetch
          reset: true

      audit_events: ->
        if helpers.can(type: 'audit_event')
          App.vent.trigger "main:layout:show:in:content",
            new App.Views.AuditEvents.Content
              collection : new App.Models.AuditEvents.Collection

          App.vent.trigger "main:layout:show:in:sidebar",
            new App.Views.AuditEvents.Filters
              collection : new App.Models.AuditEvents.Users

          App.vent.trigger "main:layout:sidebar:position", "right"

      integrity_monitoring: ->
        return unless helpers.can(type: 'integrity')

        servers_list = new AgentServers.ServerCollection

        serversListView = new ServicesServersView
          collection: servers_list
          resize_container : $ App.Layouts.Application.sidebar.el

        @listenTo servers_list, 'select', (selected) ->
          files = new IntegrityFiles
            agent_server: selected.id
          files.section = selected

          files.reset()

          schedule_settings = new IntegrityJobSchedule
            agent_server: selected.id

          jobsCollection = new IntegrityJobs
            agent_server: selected.id

          integrityView = new IntegrityFilesView
            collection : files
            jobs: jobsCollection
            model: schedule_settings

          App.vent.trigger "main:layout:show:in:content", integrityView

          schedule_settings.fetch()
          jobsCollection.fetch
            reset: true

        App.Layouts.Application.sidebar.show serversListView

        servers_list.fetch()

      services: ->
        servers_list = new AgentServers.ServerCollection
        service_list = new Services.ServiceCollection

        _showError = (action, services = '') ->
          App.Notifier.showError
            title: App.t 'settings.services_tab'
            text: App.t "settings.services.services_#{action}_fail",
              services: services
            hide: true

        _showSuccess = (action) ->
          App.Notifier.showSuccess
            title: App.t 'settings.services_tab'
            text: App.t "settings.services.services_#{action}_done"
            hide: true

        serversListView = new ServicesServersView
          collection: servers_list
          resize_container : $ App.Layouts.Application.sidebar.el

        @listenTo servers_list, 'select', (selected) ->
          if selected
            service_list.server = selected.id
            service_list.section = selected

            serviceView = new ServicesView.Services
              collection : service_list

            @listenTo serviceView, 'start stop restart', (selected, action) ->
              if selected
                service_list[action] selected
                .done (result) ->
                  failed_serices = _.pick(result, (val) -> val is false)
                  if _.isEmpty failed_serices
                    _showSuccess action
                  else
                    _showError action, _.keys(failed_serices).join(', ')

                  service_list.fetch
                    reset: true
                .fail (resp) -> _showError action

            App.Layouts.Application.content.show serviceView

            service_list.fetch
              reset: true
          else
            App.Layouts.Application.content.show new ServicesView.ServicesEmpty


        App.Layouts.Application.sidebar.show serversListView
        App.Layouts.Application.content.show new ServicesView.ServicesEmpty

        servers_list.fetch()

      setup: ->
        # TODO удалить вьюхи сайдбара, если окажутся ненужны
        App.vent.trigger "main:layout:hide:sidebar"

        model = new NetworkSettings.Model
        App.vent.trigger "main:layout:show:in:content", new App.Views.Settings.SetupNetwork model : model

        model.fetch
          wait: true

      plugins: ->
        # Initializing models and collections
        pluginsCollection = new PluginsCollection

        # Initializing views
        pluginsList = new PluginsListView
          collection : pluginsCollection

        @listenTo pluginsList, 'add_plugin', ->
          model = new AddPluginModel()

          App.modal.show new PluginsAddView
            title : App.t "settings.plugins.add_plugin"
            model : model
            callback: (file) ->
              model.sendData(file)
              .done ->
                App.modal.empty()
                pluginsCollection.fetch()
              .fail ->
                throw new Error("Can't add plugin")

        @listenTo pluginsList, 'remove_plugin', (options) ->
          selected = options.collection.getSelectedModels()

          return if selected[0].get 'IS_SYSTEM'

          App.Helpers.confirm
            title   : App.t 'menu.plugins'
            data    : App.t "settings.plugins.plugin_delete_question",
              plugin: selected[0].get 'DISPLAY_NAME'
            accept : ->
              selected[0].destroy
                wait: true

        @listenTo pluginsCollection, 'select', (model) ->
          if model
            tokensView = new TokensView
              collection : model.get 'tokens'

            tokensView.on 'create_token', ->
              model.get('tokens').create()

            tokensView.on 'regenerate_token', ->
              selected = tokensView.getSelectedModels()

              async.each selected, (model, callback) ->
                model.regenerate()
                .done ->
                  callback()
                .fail (jqXHR, textStatus, errorThrown) ->
                  callback(textStatus)
              , (err) ->
                tokensView.collection.fetch
                  data:
                    filter:
                      PLUGIN_ID: model.id
                  reset: true
                  wait: true

            tokensView.on 'edit:inline', (item, field, value, callback) ->
              data = {}
              data[field] = value

              item.save data,
                wait: true
                error: (model, xhr) ->
                  response = $.parseJSON(xhr.responseText)
                  keys = _.keys response

                  for key in keys
                    errors = response[key]

                    switch key
                      when 'VALUE'
                        if 'not_unique_field' in errors
                          err = App.t 'lists.resources.resource_contstraint_violation_error'
                      else
                        err = App.t 'global.undefined_error'

                  callback(err)

            tokensView.on 'remove_tokens', ->
              selected = tokensView.getSelectedModels()

              if selected.length
                App.Helpers.confirm
                  title   : App.t 'settings.plugins.tokens'
                  data    : App.t 'settings.plugins.token_delete_question',
                    token: _.map(selected, (model) -> model.get 'DISPLAY_NAME').join(', ')
                  accept  : ->
                    for model in selected
                      model.destroy wait : true

            App.vent.trigger "main:layout:show:in:content", new PluginInfo.PluginInfo
              model : model
              tokensView: tokensView

        App.vent.trigger "main:layout:show:in:sidebar", pluginsList
        App.vent.trigger "main:layout:show:in:content", new PluginInfo.EmptyPluginInfo()

        pluginsCollection.fetch()

      update: ->
        App.vent.trigger "main:layout:hide:sidebar"
        App.vent.trigger "main:layout:show:in:content", new UpdatePage

    # ---------------------------
    # Initializers And Finalizers
    # ---------------------------
    Settings.addInitializer ->
      App.Controllers.Settings = new SettingsController()

    Settings.addFinalizer ->
      App.Controllers.Settings.destroy()

      App.Layouts.Application.sidebar.$el?.parent()
      .addClass style.className.positionLeft
      .removeClass style.className.positionRight
