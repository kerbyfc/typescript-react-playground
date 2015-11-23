"use strict"

config = require "settings/config"
helpers = require "common/helpers.coffee"
require "i18next"

require "controllers/application.coffee"
require "controllers/popover.coffee"
require "controllers/policy.coffee"
require "controllers/dashboards.coffee"
require "controllers/organization.coffee"
require "controllers/protected.coffee"
require "controllers/analysis.coffee"
require "controllers/login.coffee"
require "controllers/events.coffee"
require "controllers/lists.coffee"
require "controllers/settings.coffee"
require "controllers/file.coffee"
require "controllers/crawler.coffee"
require "controllers/reports.coffee"

Guardian = require "behaviors/common/guardian.coffee"
bookworm = require "controllers/bookworm.coffee"

App.module "Application",
  startWithParent: false
  define: (Application, App) ->

    class ApplicationRouter extends Marionette.AppRouter


      # *************
      #  PRIVATE
      # *************
      _reload_module = ->
        Backbone.history.loadUrl(
          _.trim location.pathname, "/"
        )

      routes:
        "policy"                            : "policy"
        "policy/:id"                        : "policy_id"
        "dashboards"                        : "dashboards"
        "dashboards/:id"                    : "dashboards"

        "settings"                          : "settings"
        "settings/ldap"                     : "settings_ldap"
        "settings/access"                   : "settings_users_and_roles"
        "settings/license"                  : "settings_license"
        "settings/system_check"             : "settings_system_check"
        "settings/audit_events"             : "settings_audit_events"
        "settings/healthcheck"              : "settings_system_check"
        "settings/integrity_monitoring"     : "settings_integrity_monitoring"
        "settings/services"                 : "settings_services"
        "settings/update"                   : "settings_update"
        "settings/network"                  : "settings_network"
        "settings/crash_notice"             : "settings_crash_notice"
        "settings/plugins"                  : "settings_plugins"

        "organization/:type"                : "organization_query"
        "organization/person/:id"           : "organization_person"
        "organization/group/:id"            : "organization_group"
        "organization/:group_id/:type/:id"  : "organization_identity_with_group"
        "organization"                      : "organization_index"

        "protected"                         : "protected"
        "protected/:catalog_id"             : "protected"
        "protected/:catalog_id/:id"         : "protected"

        "events"                            : "events"
        "events?*queryString"               : "events"

        "analysis/:type"                    : "analysis"
        "analysis/:type/:category_id"       : "analysis"
        "analysis/:type/:category_id/:id"   : "analysis"

        "lists"                             : "lists_tag"
        "lists/resources"                   : "lists_resources"
        "lists/tag"                         : "lists_tag"
        "lists/statuses"                    : "lists_statuses"
        "lists/resources/:id"               : "lists_resources_query"
        "lists/perimeters"                  : "lists_perimeters"
        "lists/perimeters/"                 : "lists_perimeters"
        "lists/perimeters/:id"              : "lists_perimeters_query"


        "file"                              : "file"
        "file/:type"                        : "file"
        "file/:type/:id"                    : "file"

        "crawler"                           : "crawler"

        "reports"                           : "reports"
        "reports/folders/new"               : "add_folder"
        "reports/folders/:id"               : "show_folder"
        "reports/folders/:id/edit"          : "edit_folder"

        "reports/new/edit"                  : "add_report"

        "reports/:id"                       : "show_report"
        "reports/:id/edit"                  : "edit_report"

        "reports/:id/widgets/:wid"          : "edit_widget"
        "reports/:id/widgets/:wid/:tab"     : "edit_widget"

        "reports/:id/runs"                  : "show_report_runs"
        "reports/:id/runs/:run_id"          : "show_report_run"

        ""                                  : ""

      history: []

      initialize: ->
        @listenTo App.vent, "nav", @nav
        @listenTo App.vent, "nav:back", @navBack

        @listenTo App.vent, "reload:module", _reload_module

      ###*
       * Navigate to route
       * @param  {String} route
       * @param  {Object} options = {}
       * @param  {Boolean} trigger or not @see Backbone.Router
      ###
      nav: (route, options = {}, trigger = true) =>
        if route
          @navigate route, _.defaults options, trigger: trigger

      ###*
       * Go back if history isn't empty, else try to
       * navigate to route if it was passed
       * @param  {String} route
       * @param  {Object} options = {}
      ###
      navBack: (route, options = {}) =>
        # if route wasn't passed go back anyway
        if window.history.state? or not route
          if options.trigger is false
            if @history.length
              @navigate @history[@history.length-1], trigger: false
          else
            window.history.back()
        # navigate if history is empty and route was passed
        else
          @nav route, options

      getCurrentRoute: ->
        frag = Backbone.history.fragment
        if _.isEmpty(frag) then null else frag

      _route: (module, options) ->
        App.Layouts.Application.sidebar.$el.closest("aside").removeClass('_right')

        if module and module isnt @currentModuleName
          $.xhrPool.abortAll()

          name = module.replace /^./, (b) -> b.toUpperCase()

          url = window.location.pathname.replace(/\//, '') or module

          # TODO: в дальнейшем убрать, если придти к единому наименованию модулей
          # и реализовать единый подход к обработке ссылок
          switch module
            when 'analysis'
              _options = url: "#{module}/#{options.params[0]}"
            when 'settings'
              _options = url: url
            else _options = module: module

          islock = helpers.islock _options
          # check access
          if islock and module isnt "Crawler"
            App.Notifier.showError
              title : App.t "menu.#{options.params[0] or module}"
              text  : islock.message
              hide  : true
            return false
          else
            # switch module
            App.vent.trigger "start:module", name, options
            return true
        else
          return true

      getDefaultModule: ->
        switch true
          when helpers.can(module: config.defaultModule)
            config.defaultModule
          when helpers.can(module: config.adminDefaultModule)
            config.adminDefaultModule
          else
            false

      execute: (callback, params, method_name) =>
        route = _.findKey @routes, (val) -> val is method_name

        # try to find view, that should not be destroyed
        _protected = App.Layouts.Application.regionManager.find (reg) ->
          if view = reg.currentView
            # if views data is protected by guardian behavior
            # check if guardian passes checks
            if _.find(view._behaviors, (behavior) -> behavior instanceof Guardian) and
                _.isFunction(view.approveNavigation) and
                not view.approveNavigation.call view, route, params
              return true
          false

        if _protected
          App.vent.trigger "nav:back", "/", trigger: false
          return false # prevent routing

        # history for silent rollbacks
        @history.push Backbone.history.fragment

        route  = route.substr(0, route.length - 1) if route.substr(-1) is '/'
        route  = route.split('?')[0]
        module = route.split("/")[0] or @getDefaultModule()

        sub_route = route.indexOf('/') is -1 and
          route.substring(route.indexOf('/')+1) or
          ''

        r = @_route module,
          route  : sub_route
          params : params

        return unless r

        @currentModuleName = module or null

        callback?.apply @, params

      policy_id: (id) ->
        App.Policy.filter = name: [ ID: id ]

      organization_index: ->
        App.Controllers.Organization.index()

      organization_person: (id) ->
        App.Controllers.Organization.index
          identity_id : id
          type        : 'person'

      organization_group: (id) ->
        App.Controllers.Organization.index
          group_id    : id

      lists_resources: ->
        App.Controllers.Lists.resources()

      lists_tag: ->
        App.Controllers.Lists.tags()

      settings_ldap: ->
        App.Controllers.Settings.ldap()

      settings_users_and_roles: ->
        App.Controllers.Settings.users_and_roles()

      settings_license: ->
        App.Controllers.Settings.license()

      settings_system_check: ->
        App.Controllers.Settings.system_check()

      settings_audit_events: ->
        App.Controllers.Settings.audit_events()

      settings_integrity_monitoring: ->
        App.Controllers.Settings.integrity_monitoring()

      settings_services: ->
        App.Controllers.Settings.services()

      settings_network: ->
        App.Controllers.Settings.setup()

      settings_crash_notice: ->
        App.Controllers.Settings.crash_notice()

      settings_plugins: ->
        App.Controllers.Settings.plugins()

      settings_update: ->
        App.Controllers.Settings.update()

      lists_statuses: ->
        App.Controllers.Lists.statuses()

      lists_resources_query: (id) ->
        App.Controllers.Lists.resources(id)

      lists_perimeters: ->
        App.Controllers.Lists.perimeters()

      lists_perimeters_query: (id) ->
        App.Controllers.Lists.perimeters(id)

      reports: ->
        App.Controllers.Reports.show()

      show_report: (id) ->
        App.Controllers.Reports.showReport id

      edit_report: (id) ->
        App.Controllers.Reports.editReport id

      add_report: ->
        App.Controllers.Reports.addReport "new"

      add_folder: ->
        App.Controllers.Reports.addFolder "new"

      edit_folder: (id) ->
        App.Controllers.Reports.editFolder id

      show_folder: (id) ->
        App.Controllers.Reports.showFolder id

      show_report_runs: (id) ->
        App.Controllers.Reports.showReportRuns id

      show_report_run: (id, runId) ->
        App.Controllers.Reports.showReportRun id, runId

      edit_widget: (reportId, widgetId, tab = "") ->
        App.Controllers.Reports.editWidget reportId, widgetId, tab

      organization_query: (type) ->
        queryString = {}
        location.href.replace(
          new RegExp("([^?=&]+)(=([^&]*))?", "g"), ($0, $1, $2, $3) ->
            queryString[$1] = $3
        )

        queryString.type = type.split('?')[0]

        App.Controllers.Organization.index queryString

      analysis: -> App.Controllers.Analysis?.index arguments...

      protected: -> App.Controllers.Protected?.index arguments...

      file: -> App.Controllers.File?.index arguments...

      organization_identity_with_group: (group_id, type, id) ->
        App.Controllers.Organization.index
          group_id  : group_id
          identity_id : id
          type    : type

      crawler: ->
        App.Controllers.Crawler?.index arguments...

    # Initializers And Finalizers
    # ---------------------------
    Application.addInitializer ->
      App.Routes.Application = new ApplicationRouter
      if Backbone.history and not Backbone.History.started
        Backbone.history.start
          pushState: true
          root: "/"
        App.vent.trigger "history:start"

    Application.addFinalizer ->
      Backbone.history.stop()
      delete App.Routes.Application
