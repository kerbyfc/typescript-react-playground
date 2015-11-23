"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/tab_view.coffee"

WidgetsView = require "views/dashboards/widgets.coffee"

App.module "Dashboards",
  startWithParent: false
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards ?= {}

    class App.Views.Dashboards.TabItem extends App.Views.Controls.TabChildView
      triggers:
        "click .adaptiveTabs__btn-delete"     : "delete_hide_dashboard"

      attributes: ->
        "data-id": @model.id


    class App.Views.Dashboards.Content extends App.Views.Controls.TabView

      className: "content"

      regions:
        tabContent: "#tm-dashboards-tab-content"

      childView: App.Views.Dashboards.TabItem

      childViewContainer: "#tm-dashboards-tabs"

      template: "dashboards/content"

      ui:
        addDashboard    : '[data-action="add-tab"]'
        selectWidget    : '[data-action="add-widget"]'
        selectLayout    : '[data-action="select-layout"]'
        generateReport    : '[data-action="generate-report"]'
        showReports     : '[data-action="show-reports"]'

      triggers:
        "click [data-action='add-tab']:not('.button-disabled')"     : 'tab:add'
        "click [data-action='add-widget']:not('.button-disabled')"    : "choseWidget"
        "click [data-action='select-layout']:not('.button-disabled')" : "choseLayout"
        "click [data-action='generate-report']:not('.button-disabled')" : "generateReport"
        "click [data-action='show-reports']:not('.button-disabled')"  : "showReports"

      config:
        draggable: true
        editable: true
        displayKey: 'DISPLAY_NAME'

        childViewTemplate: "dashboards/tab"

        baseView: WidgetsView

      blockToolbar: ->
        @ui.addDashboard.addClass("button-disabled")
        @ui.selectLayout.addClass("button-disabled")
        @ui.selectWidget.addClass("button-disabled")
        @ui.generateReport.addClass("button-disabled")

      updateToolbar: ->
        @blockToolbar()

        if helpers.can({action: 'edit', type: 'dashboard'}) and @collection.length isnt 0
          @ui.addDashboard.removeClass("button-disabled")
          @ui.selectLayout.removeClass("button-disabled")
          @ui.selectWidget.removeClass("button-disabled")
          @ui.generateReport.removeClass("button-disabled")

      onShow: ->
        super()

        # Убираем sidebar если он был открыт
        $(App.Layouts.Application.sidebar.el).closest('.sidebar').hide()

      toggleGenerateReportButton: (view) ->
        if view?.collection.length is 0
          @ui.generateReport.prop("disabled", true)
        else
          if _.some(view?.collection.models, (widget) -> widget.get('STATTYPE_ID') isnt 4)
            @ui.generateReport.prop("disabled", false)
          else
            @ui.generateReport.prop("disabled", true)

      initialize: ->
        super _.extend @config, @options

        @on 'add:child remove:child render:collection', ->
          @updateToolbar()

          @ui.addDashboard.removeClass("button-disabled") if helpers.can({action: 'edit', type: 'dashboard'})

        @on 'after:tab_changed', (view) =>
          # Если кол-во виджетов равно 0, то запрещаем генерацию отчетов
          @toggleGenerateReportButton(view)

          # Если после изменения состава виджетов для дашборда
          # кол-во виджетов стало равно 0, то запрещаем генерацию отчета
          @currentView.on 'item:add item:remove collection:rendered', =>
            @toggleGenerateReportButton(@currentView)

        @on 'before:tab_changed', (view) ->
          view.on 'add:child remove:child render:collection', =>
            @toggleGenerateReportButton(view)

        @on "reorder:finish", ->
          tabs = @$childViewContainer.children()
          ids = for tab, i in tabs
            tabs.eq(i).data("id")

          @collection.save_reorder(ids)

      getSelected: ->
        return @currentView
