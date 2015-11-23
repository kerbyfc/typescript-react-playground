"use strict"

Catalogs = require "models/dashboards/catalog.coffee"
Widget = require "views/dashboards/renderers/widget.coffee"

class EmptyProtectedCatalogItem extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class ProtectedCatalogItem extends Marionette.ItemView

  template: "dashboards/widgets/protected_catalogs/protectedCatalog_list_item"

  tagName: 'tr'

  events:
    "click .stat": "drillToCatalog"

  drillToCatalog: (e) ->
    e?.preventDefault()

    $target = $(e.currentTarget)

    if $target.html() is '0' then return

    url_params =
      FROM                : @model.collection.start_date.unix()
      TO                  : @model.collection.end_date.unix()
      VIOLATION_LEVEL     : $target.data('threat')
      RULE_GROUP_TYPE     : @model.collection.RULE_GROUP_TYPE
      PROTECTED_CATALOGS  : @model.get 'CATALOG_ID'

    App.Routes.Application.navigate "/events?#{$.param(url_params)}", {trigger: true}

class ProtectedCatalogsList extends Marionette.CompositeView

  childView: ProtectedCatalogItem

  childViewContainer: 'tbody'

  emptyView: EmptyProtectedCatalogItem

  template: "dashboards/widgets/protected_catalogs/protectedCatalog_list"

exports.WidgetSettings = class CategoryStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/protected_catalogs/widget_settings"

exports.WidgetView = class ProtectedCatalogStats extends Widget.WidgetView

  defaultVisualType: "grid"

  template: "dashboards/widgets/protected_catalogs/widget_view"

  templateHelpers: ->
    locale: App.t 'dashboards.widgets', { returnObjectTrees: true }

  regions:
    protectedCatalogsList: "#protectedCatalog_list"
    paginator: "#protectedCatalog_paginator"

  initialize: ->
    @collection = new Catalogs()

    baseopt = @model.get('BASEOPTIONS')

    if baseopt.protected_catalogs
      @collection.protected_catalogs = _.map baseopt.protected_catalogs, (catalog) -> catalog.ID

    if not @collection.start_date and not @collection.end_date
      baseopt = @model.get('BASEOPTIONS')
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  grid: ->
    @paginator.show new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: false

    @protectedCatalogsList.show new ProtectedCatalogsList
      collection: @collection

    @collection.fetch
      reset: true
      wait: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @
