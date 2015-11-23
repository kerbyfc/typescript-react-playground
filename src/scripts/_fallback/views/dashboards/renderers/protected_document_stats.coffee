"use strict"

Documents = require "models/dashboards/protected_document.coffee"
Widget = require "views/dashboards/renderers/widget.coffee"

class EmptyProtectedDocumentItem extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class ProtectedDocumentItem extends Marionette.ItemView

  template: "dashboards/widgets/protected_documents/protectedDocument_list_item"

  tagName: 'tr'

  events:
    "click .stat": "drillToDocument"

  drillToDocument: (e) ->
    e?.preventDefault()

    $target = $(e.currentTarget)
    if $target.html() is '0' then return

    url_params =
      FROM                  : @model.collection.start_date.unix()
      TO                    : @model.collection.end_date.unix()
      PROTECTED_DOCUMENTS   : @model.get 'DOCUMENT_ID'
      VIOLATION_LEVEL       : $target.data('threat')

    # Get rule group type
    if @model.collection.RULE_GROUP_TYPE
      url_params['RULE_GROUP_TYPE'] = @model.collection.RULE_GROUP_TYPE

    App.Routes.Application.navigate "/events?#{$.param(url_params)}", {trigger: true}

class ProtectedDocumentsList extends Marionette.CompositeView

  childView: ProtectedDocumentItem

  childViewContainer: 'tbody'

  emptyView: EmptyProtectedDocumentItem

  template: "dashboards/widgets/protected_documents/protectedDocument_list"


exports.WidgetSettings = class ProtectedDocumentStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/protected_documents/widget_settings"

exports.WidgetView = class ProtectedDocumentStats extends Widget.WidgetView

  defaultVisualType: "grid"

  template: "dashboards/widgets/protected_documents/widget_view"

  regions:
    protectedDocumentsList: "#protectedDocument_list"
    paginator: "#protectedDocument_paginator"

  initialize: ->
    baseopt = @model.get('BASEOPTIONS')

    @collection = new Documents()

    if baseopt.protected_documents
      @collection.protected_documents = _.map baseopt.protected_documents, (document) -> document.ID

    if baseopt.protected_catalogs
      @collection.protected_catalogs = _.map baseopt.protected_catalogs, (catalog) -> catalog.ID

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  grid: ->
    @protectedDocumentsList.show new ProtectedDocumentsList
      collection: @collection

    @paginator.show new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: false

    @collection.fetch
      reset: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @
