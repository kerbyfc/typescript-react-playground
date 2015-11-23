"use strict"

StatusesStat = require "models/dashboards/status.coffee"
Widget = require "views/dashboards/renderers/widget.coffee"

class EmptyStatusItem extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class StatusItem extends Marionette.ItemView

  template: "dashboards/widgets/status/status_list_item"

  tagName: 'tr'

  events:
    "click .workstation_stat": "drillToWorkstation"
    "click .person_stat": "drillToPerson"

  drillToPerson: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).html() is '0' then return

    url_params =
      status        : $(e.currentTarget).data('status')
      STATUS_FROM   : @model.collection.start_date.unix()
      STATUS_TO     : @model.collection.end_date.unix()

    App.Routes.Application.navigate "/organization/persons?#{$.param(url_params)}", {trigger: true}

  drillToWorkstation: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).html() is '0' then return

    url_params =
      status        : $(e.currentTarget).data('status')
      STATUS_FROM   : @model.collection.start_date.unix()
      STATUS_TO     : @model.collection.end_date.unix()

    App.Routes.Application.navigate "/organization/workstations?#{$.param(url_params)}", {trigger: true}

class Statuses extends Marionette.CompositeView

  childView: StatusItem

  emptyView: EmptyStatusItem

  childViewContainer: 'tbody'

  template: "dashboards/widgets/status/status_list"

exports.WidgetSettings = class StatusStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/status/widget_settings"

exports.WidgetView = class StatusStats extends Widget.WidgetView

  template: "dashboards/widgets/status/widget_view"

  templateHelpers: ->
    locale: App.t 'dashboards.widgets', { returnObjectTrees: true }

  defaultVisualType: "grid"

  regions:
    statusList: "[data-region='status_list']"
    paginator: "[data-region='status_paginator']"

  initialize: ->
    baseopt = @model.get('BASEOPTIONS')

    @collection = new StatusesStat()

    @listenTo @collection, 'sync', @_reloadData

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  grid: ->
    @paginator.show new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: false

    @statusList.show new Statuses
      collection: @collection

    @collection.fetch
      reset: true
      wait: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or 'grid'

    @[visualType].call @ if visualType?
