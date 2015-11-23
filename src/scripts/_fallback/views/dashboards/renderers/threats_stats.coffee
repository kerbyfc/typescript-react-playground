"use strict"

Threat = require "models/dashboards/threat.coffee"
Widget = require "views/dashboards/renderers/widget.coffee"

class EmptyThreatItem extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class ThreatGridItem extends Marionette.ItemView

  template: "dashboards/widgets/threat/threat_list_grid_item"

  tagName: 'tr'

class ThreatsInfoGrid extends Marionette.CompositeView

  childView: ThreatGridItem

  childViewContainer: 'tbody'

  emptyView: EmptyThreatItem

  template: "dashboards/widgets/threat/threat_list_grid"

class ThreatHorizontalBarItem extends Marionette.ItemView

  template: "dashboards/widgets/threat/threat_list_hb_item"

class ThreatsInfoHorizontalBar extends Marionette.CompositeView

  childView: ThreatHorizontalBarItem

  childViewContainer: 'div'

  emptyView: EmptyThreatItem

  template: "dashboards/widgets/threat/threat_list_hb"

exports.WidgetSettings = class ThreatStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/threat/widget_settings"

  templateHelpers: ->
    stattype: @options.stattype

exports.WidgetView = class ThreatsStats extends Widget.WidgetView

  template: "dashboards/widgets/threat/widget_view"

  defaultVisualType: "horizontal-bar"

  events:
    "click .stat": "drillToLevel"
    "click .widgetThreatCount__total, .count_grid": "drillToObjects"

  regions:
    threatInfo: ".widgetThreatCount"

  drillToObjects: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).html() is '0' then return

    params =
      FROM            : @collection.start_date.unix()
      TO              : @collection.end_date.unix()
      RULE_GROUP_TYPE : $(e.currentTarget).data('type')
      VIOLATION_LEVEL : 'High,Medium,Low'

    App.Routes.Application.navigate "/events?#{$.param(params)}", {trigger: true}

  drillToLevel: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).html() is '0' then return

    params =
      FROM            : @collection.start_date.unix()
      TO              : @collection.end_date.unix()
      RULE_GROUP_TYPE : $(e.currentTarget).data('type')
      VIOLATION_LEVEL : _.capitalize $(e.currentTarget).parent().data('threat')

    App.Routes.Application.navigate "/events?#{$.param(params)}", {trigger: true}

  initialize: ->
    @collection = new Threat.ThreatStat

    baseopt = @model.get('BASEOPTIONS')

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  "horizontal-bar": ->
    @threatInfo.show new ThreatsInfoHorizontalBar
      collection: @collection
      filter: (child, index, collection) ->
        if App.Setting.get('product') is "pdp" and child.get('type') is 'Placement'
          return false
        else
          return true

    @collection.fetch
      reset: true

  grid: ->
    @threatInfo.show new ThreatsInfoGrid
      collection: @collection
      filter: (child, index, collection) ->
        if App.Setting.get('product') is "pdp" and child.get('type') is 'Placement'
          return false
        else
          return true

    @collection.fetch
      reset: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @
