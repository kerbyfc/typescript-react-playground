"use strict"

Dashboard = require "models/dashboards/dashboards.coffee"
require "models/dashboards/stattype.coffee"
DashboardReports = require "models/dashboards/generate_reports.coffee"

LinearModel = require "backbone.linear"

require "views/dashboards/widgets.coffee"
require "views/dashboards/content.coffee"
require "views/controls/table_view.coffee"

SelectLayoutDialog = require "views/dashboards/dialogs/select_layout.coffee"
DashboardCreateView = require "views/dashboards/dialogs/dashboard_create.coffee"
ReportsDialog = require "views/dashboards/dialogs/reports.coffee"
SelectWidgetsDialog = require "views/dashboards/dialogs/select_widgets.coffee"
WidgetsReportDialog = require "views/dashboards/dialogs/generate_report.coffee"

App.module "Dashboards",
  startWithParent: false
  define: (Dashboards, App, Backbone, Marionette, $) ->

    class DashboardsController extends Marionette.Controller

      initialize: (options) ->
        App.Timers.Dashboards ?= {}

        dashboards = new Dashboard.Collection
        contentView = new App.Views.Dashboards.Content {
          collection: dashboards, initialTab: options.params[0] if options.params?.length
        }

        @listenTo contentView, 'childview:delete_hide_dashboard', (childView) ->
          App.Helpers.confirm(
            confirm : [
              App.t 'global.delete'
            ]
            title : App.t 'dashboards.dashboards.delete_dashboard_title'
            data: App.t 'dashboards.dashboards.delete_dashboard_question',
              name: childView.model.get 'DISPLAY_NAME'
            accept: ->
              childView.model.destroy()
          )

        @listenTo contentView, 'choseWidget', ->
          selectedDashboard = contentView.getSelected()

          widgetsView = new SelectWidgetsDialog
            collection: selectedDashboard.stattypes
            dashboard: selectedDashboard.model
            widgets: selectedDashboard.collection

          widgetsView.on 'childview:addWidget', (view, opt) ->
            selectedDashboard.collection.create
              COL: 0
              LINE: 0
              SIZEX: 1
              SIZEY: 1
              STATTYPE_ID: view.model.get "STATTYPE_ID"
              DASHBOARD_ID: selectedDashboard.model.id,
                wait: true
                success: ->
                  selectedDashboard.trigger "item:add"

          App.modal.show widgetsView

        @listenTo contentView, 'generateReport', ->
          selectedDashboard = contentView.getSelected()
          collection = contentView.currentView.collection.clone()

          reportModel = new DashboardReports.Model(
            null
            {dashboard:selectedDashboard.model, widgets:collection}
          )

          App.modal.show new WidgetsReportDialog
            model:reportModel
            callback: (model) ->

              model.save(
                null
                {
                  wait: true
                  success: (result) ->
                    App.modal.empty()
                    App.Notifier.showSuccess
                      title: App.t 'menu.dashboards'
                      text: App.t 'dashboards.dashboards.generate_report_message',
                        name: model.get('DISPLAY_NAME')
                      hide: true

                  error: (model, xhr, options) ->
                    App.Notifier.showError
                      title: App.t 'menu.dashboards'
                      text: App.t 'dashboards.dashboards.dashboard_error'
                      hide: true
                }
              )

        # Изменение структуры дашборда
        @listenTo contentView, 'choseLayout', ->
          selectedDashboard = contentView.getSelected()

          App.modal.show new SelectLayoutDialog
            model: selectedDashboard.model
            callback: (value) ->
              selectedDashboard.model.save LAYOUT: parseInt(value.LAYOUT, 10),
                wait: true
                success: ->
                  App.modal.empty()
                  selectedDashboard.collection.fetch
                    data:
                      filter:
                        DASHBOARD_ID:
                          selectedDashboard.model.get 'DASHBOARD_ID',
                    reset: true
                    wait: true

        @listenTo contentView, 'showReports', ->
          collection = new DashboardReports.Collection()

          collection.config =
            _CONFIG_: "ACTIVE"

          App.modal.show new ReportsDialog
            title: App.t 'dashboards.dashboards.reports'
            collection: collection

          # Формируем параметры запроса
          if not collection.sortRule
            collection.sortRule = sort:
              "COMPLETE_DATE": "ASC"

          collection.fetch
            reset: true
            wait: true

        @listenTo contentView, 'tab:add', ->
          model = new dashboards.model()

          App.modal.show new DashboardCreateView
            title: App.t 'dashboards.dashboards.add_dashboard_title'
            model: model
            callback: (data) ->
              model.save(
                {
                  DISPLAY_NAME : data.DISPLAY_NAME
                  IS_HIDDEN  : 0
                  USER_ID    : App.Session.currentUser().get('USER_ID')
                  LAYOUT     : 3
                }
                {
                  wait: true
                  success: (model, collection, options) ->
                    App.modal.empty()

                    dashboards.add model
                  error: (model, xhr, options) ->
                    switch xhr.status
                      when 400
                      # TODO: Костыль, как бэк научится отдавать правильно ошибку
                      # добавить обработку кода ошибки
                        error = App.t 'dashboards.dashboards.name_violation_error'
                      else error = App.t 'dashboards.dashboards.undefined_error'

                    App.modal.currentView.showErrorHint('name', error)
                }
              )

        App.Layouts.Application.content.show contentView

        dashboards.fetch
          reset: true
          wait: true

    # Initializers And Finalizers
    # ---------------------------
    Dashboards.addInitializer (options) ->
      App.Controllers.Dashboards = new DashboardsController(options)


    Dashboards.addFinalizer ->
      _.each App.Timers.Dashboards, (timerId) ->
        clearInterval timerId

      delete App.Controllers.Dashboards
