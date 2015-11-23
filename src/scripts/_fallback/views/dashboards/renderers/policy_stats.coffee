"use strict"

require "views/controls/paginator.coffee"
PoliciesStat = require "models/dashboards/policy.coffee"
Widget = require "views/dashboards/renderers/widget.coffee"

class EmptyPolicyItem extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class PolicyItem extends Marionette.ItemView

  template: "dashboards/widgets/policies/policy_list_item"

  tagName: 'tr'

  events:
    "click .stat": "drillToPolicy"

  drillToPolicy: (e) ->
    e?.preventDefault()

    $target = $(e.currentTarget)

    if $target.html() is '0' then return

    url_params =
      FROM            : @model.collection.start_date.unix()
      TO              : @model.collection.end_date.unix()
      RULE_GROUP_TYPE : $target.data('type')
      POLICIES        : @model.get 'POLICY_ID'

    App.Routes.Application.navigate "/events?#{$.param(url_params)}", {trigger: true}

class Policies extends Marionette.CompositeView

  childView: PolicyItem

  childViewContainer: 'tbody'

  emptyView: EmptyPolicyItem

  template: "dashboards/widgets/policies/policy_list"


exports.WidgetSettings = class PolicyStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/policies/widget_settings"

exports.WidgetView = class PolicyStats extends Widget.WidgetView

  defaultVisualType: "grid"

  template: "dashboards/widgets/policies/widget_view"

  templateHelpers: ->
    locale: App.t 'dashboards.widgets', { returnObjectTrees: true }

  regions:
    policyList  : "#policy_list"
    paginator   : "#paginator"

  initialize: ->
    baseopt = @model.get('BASEOPTIONS')

    @collection = new PoliciesStat()

    if baseopt.policies
      @collection.policies = _.map baseopt.policies, (policy) -> policy.ID

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  grid: ->
    @paginator.show new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: false

    @policyList.show new Policies
      collection: @collection

    @collection.fetch
      reset: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @
