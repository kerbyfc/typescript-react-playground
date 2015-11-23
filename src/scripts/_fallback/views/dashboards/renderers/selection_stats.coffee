"use strict"

Events = require "models/events/events.coffee"
Selections = require "models/events/selections.coffee"
require "behaviors/events/entity_info.coffee"

require "views/dashboards/widgets.coffee"

Widget = require "views/dashboards/renderers/widget.coffee"

class EventItem extends Marionette.ItemView

  template: "dashboards/widgets/selection/event_item"

  className: "widgetSelectionItem"

  templateHelpers: ->
    object_type_code: @options.object_type_codes.get(@model.get('OBJECT_TYPE_CODE'))

class EventsViewEmpty extends Marionette.ItemView

  template: "dashboards/widgets/selection/empty"

  templateHelpers: ->
    message: @options.message

class EventsView extends Marionette.CollectionView
  childView: EventItem

  className: 'widgetSelection'

  behaviors:
    EntityInfo:
      targets       : '.popover_info'
      behaviorClass : App.Behaviors.Events.EntityInfo

  childViewOptions: (model, index) ->
    return {
      object_type_codes: @object_type_codes
    }

  initialize: ->
    @object_type_codes = App.request 'bookworm', 'event'

exports.WidgetSettings = class SelectionStatsSettings extends Widget.WidgetSettings

  template: "dashboards/widgets/selection/widget_settings"

  onShow: ->
    @selections_collection = new Selections.collection [], params:
      filter:
        QUERY_TYPE: "query"

    @$('[name="BASEOPTIONS[selection]"]').select2
      allowClear: true
      placeholder: App.t 'dashboards.widgets.selection_placeholder'
      query: (query) =>
        @selections_collection.perPage = 1000
        @selections_collection.fetch
          reset: true
          success: (collection, response, options) ->
            if query.term is ''
              data = collection
            else
              data = collection.filter (selection) ->
                name = selection.get('DISPLAY_NAME')

                name.toUpperCase().indexOf(query.term.toUpperCase())>=0

            query.callback
              more: false
              results: [
                text: App.t('events.selection.selection_group'),
                children: data.map (selection) ->
                  name = selection.get('DISPLAY_NAME')

                  {
                    id    : selection.get('QUERY_ID'),
                    text  : name
                  }
              ]
      initSelection: (element, callback) =>
        if element.val()
          @selections_collection.fetchOne element.val(), {}, (selection) ->
            callback({
              id    : selection.id
              text  : selection.get('DISPLAY_NAME')
            })

    if App.Helpers.islock({type: 'query', action: 'show'})
      @$('[name="BASEOPTIONS[selection]"]').select2('enable', false)

  validateVidgetSettings: ->
    data = @serialize()

    result = {}

    if parseInt(data.BASEOPTIONS.perPage, 10) < 0 or parseInt(data.BASEOPTIONS.perPage, 10) > 100
      result['perPage'] = App.t 'dashboards.widgets.perPage_error'

    result

exports.WidgetView = class SelectionStats extends Widget.WidgetView

  # Дефолтное отображение виджета
  defaultVisualType: 'timeline'

  template: "dashboards/widgets/selection/widget_view"

  regions:
    eventsList  : "#events_list"
    paginator   : "#paginator"

  _showQueryError: (message) ->
    if message.data.data.error
      error = message.data.data.error
    else
      if message.data.message
        if $.i18n.exists "events.events.#{message.data.message}"
          error = App.t "events.events.#{message.data.message}"
        else
          error = message.data.message

    App.Notifier.showError
      title: App.t 'menu.dashboards'
      text: App.t 'events.conditions.selection_error',
        name: message.data.data.DISPLAY_NAME
        error: error
      hide: if message.data.show is 'sticky' then false else true

  _showQueryDone: (query_id) ->
    @eventsCollection.query = filter:
      QUERY_ID  : query_id
      USER_ID   : App.Session.currentUser().get('USER_ID')

    @eventsCollection.fetch
      reset: true
      wait: true
      success: =>
        if @eventsCollection.length > 0
          @eventsList.show new EventsView collection: @eventsCollection
          @paginator.show new App.Views.Controls.Paginator
            collection: @eventsCollection
        else
          @eventsList.show new EventsViewEmpty(message: App.t 'dashboards.widgets.no_selection_events')
      error: ->
        App.Notifier.showError
          title: App.t 'menu.events'
          text: "Can't fetch events"

  timeline: ->
    @eventsCollection = new Events.Collection()
    selections_collection = new Selections.collection()

    if @model.get('BASEOPTIONS')?.perPage
      @eventsCollection.howManyPer @model.get('BASEOPTIONS')?.perPage
    else
      @eventsCollection.howManyPer 3

    if @model.get('BASEOPTIONS')?.selection
      if App.Helpers.can({type: 'query', action: 'show'})
        selections_collection.fetchOne @model.get('BASEOPTIONS')?.selection, {}, (selection) =>

          @eventsCollection.sortRule = sort: selection.get('QUERY').sort

          if not (selection.get('QUERY_ID') of App.EventsConditionsManager.Dashboards)
            # если не нашли добавляем в очередь и обновляем toolbar
            App.EventsConditionsManager.Dashboards[selection.get('QUERY_ID')] =
              started: 0

            selection.execute().done ->
              App.EventsConditionsManager.Dashboards[selection.get('QUERY_ID')].started = 1
            .fail ->
              App.Notifier.showError({
                title: "selection",
                text: "Can't execute selection"
                hide: true
              })
      else
        @eventsList.show new EventsViewEmpty(message: App.t 'dashboards.widgets.no_rights')
    else
      @eventsList.show new EventsViewEmpty(message: App.t 'dashboards.widgets.no_selection')

  onDestroy: ->
    @stopListening App.Session.currentUser(), "message"

  onRender: ->
    super

    visualType = @model.get("BASEOPTIONS")?.choosenVisualType or @defaultVisualType

    @listenTo App.Session.currentUser(), 'message', (message) =>
      query_id = message.data.data.QUERY_ID

      if message.data.module is 'selection' and query_id of App.EventsConditionsManager.Dashboards
        if parseInt(@model.get('BASEOPTIONS')?.selection, 10) isnt parseInt(query_id, 10)
          if message.data.type is 'error'
            @_showQueryError(message)
          else
            @_showQueryDone(message.data.data.QUERY_ID)

          delete App.EventsConditionsManager.Dashboards[message.data.data.QUERY_ID]

    @[visualType].call @
