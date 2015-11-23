"use strict"

UsersStat = require "models/dashboards/top_user.coffee"

require "views/controls/paginator.coffee"
require "behaviors/events/entity_info.coffee"

require "models/organization/persons.coffee"
require "views/organization/persons.coffee"

Widget = require "views/dashboards/renderers/widget.coffee"

class UsersEmpty extends Marionette.ItemView

  template: "dashboards/widgets/shared/empty_list"

class UserItem extends Marionette.ItemView

  template: "dashboards/widgets/users/user_list_item"

  behaviors:
    EntityInfo:
      targets       : '[data-type="person"]'
      behaviorClass : App.Behaviors.Events.EntityInfo

  events:
    "click .user_stat": "drillToEvents"

  drillToEvents: (e) ->
    e?.preventDefault()

    $target = $(e.currentTarget)

    if $target.data('value') is 0 then return

    params =
      FROM            : @model.collection.start_date.unix()
      TO              : @model.collection.end_date.unix()
      VIOLATION_LEVEL : $target.data('threat')
      SENDERS         : @model.get 'SENDER_ID'

    if @model.has 'DISPLAY_NAME'
      params['SENDERS_TYPE'] = 'person'
    else
      params['SENDERS_TYPE'] = 'key'

    App.Routes.Application.navigate "/events?#{$.param(params)}", {trigger: true}

class Users extends Marionette.CollectionView

  childView: UserItem

  emptyView: UsersEmpty

exports.WidgetView = class UsersView extends Widget.WidgetView

  defaultVisualType: "grid"

  template: "dashboards/widgets/users/widget_view"

  regions:
    userList: "#userList"
    paginator: "#paginator"

  initialize: ->
    @collection = new UsersStat

    baseopt = @model.toJSON().BASEOPTIONS

    @collection.top = baseopt.top

    if baseopt.user_groups
      @collection.user_groups = _.map baseopt.user_groups, (user_group) -> user_group.ID

    if baseopt.user_statuses
      @collection.user_statuses = _.map baseopt.user_statuses, (user_status) -> user_status.ID

    if not @collection.start_date and not @collection.end_date
      [@collection.start_date, @collection.end_date] = @model.createWidgetInterval()

  grid: ->
    @userList.show new Users
      collection: @collection

    @paginator.show new App.Views.Controls.Paginator
      collection: @collection

    @collection.fetch
      reset: true
      wait: true

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @[visualType].call @


exports.WidgetSettings = class UsersSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/users/widget_settings"

  onShow: ->
    if @$el.find('[name="BASEOPTIONS[top]"]').val() is ''
      @$el.find('[name="BASEOPTIONS[top]"]').val(10)

  validateWidgetSettings: ->
    data = @serialize()

    result = {}

    if not data.BASEOPTIONS.top or
       parseInt(data.BASEOPTIONS.top, 10) <= 0 or
       parseInt(data.BASEOPTIONS.top, 10) > 100
      result['top'] = App.t 'dashboards.widgets.top_error'

    return result
