"use strict"

require "views/controls/tab_view.coffee"
require "models/events/events.coffee"

co      = require "co"
helpers = require "common/helpers.coffee"

EventsListView  = require "views/events/events_list.coffee"
EventsTableView = require "views/events/events_table.coffee"
Selection       = require "models/events/selections.coffee"


# override only for events
class App.Views.Controls.EventsTabChildView extends App.Views.Controls.TabChildView

  tagName: "button"

  className: ->
    className = "button _icon "

    if @model.get("name") is 'list'
      className += "icon _viewList"
    else
      className += "icon _viewTable"

  attributes: ->
    if @model.get("name") is 'list'
      title: App.t 'events.events.event_list'
    else
      title: App.t 'events.events.event_table'

  render: ->
    super

    if name = @model.get "name"
      @$el
        .data "tab-id", name
        .attr "data-tab-id", name

module.exports = class Content extends App.Views.Controls.TabView

  className : 'content event'

  childView: App.Views.Controls.EventsTabChildView

  regions:
    tabContent                  : "#tm-events-tab-content"
    paginator                   : "#paginator"

  ui:
    selections                      : '.selections'
    toolbar_execute                 : ".eventFilter__actions [data-action='execute']"
    toolbar_create                  : ".eventFilter__actions [data-action='add']"
    toolbar_delete                  : ".eventFilter__actions [data-action='delete']"
    toolbar_edit                    : ".eventFilter__actions [data-action='edit']"
    toolbar_copy                    : ".eventFilter__actions [data-action='copy']"

    objects_toolbar_set_tag         : '[data-action="set_tag"]'
    objects_toolbar_export          : '[data-action="export"]'
    objects_toolbar_set_decision    : '[data-action="set_decision"]'
    objects_toolbar_debug           : '[data-action="debug_info"]'

    query_complete_date             : ".eventRequestInfo__date"
    query_events_count              : ".eventRequestInfo__count"
    selectionDate                   : "#selectionDate"
    eventsCount                     : '#eventsCount'

  triggers:
    "click [data-action='debug_info']"                      : "downloadObject"
    'click [data-action="set_tag"]'                         : 'setTags'
    'click [data-action="export"]'                          : 'export'
    "click [data-action='copy']"                            : 'copy_query'
    "click .eventFilter__actions [data-action='delete']:not(:disabled)"    : 'delete_query'
    "click .eventFilter__actions [data-action='execute']:not(:disabled)"   : 'execute_query'
    "click .eventFilter__actions [data-action='edit']:not(:disabled)"      : 'edit_query'

  events:
    'click [data-action="set_decision"]'                        : 'setDecision'
    'click .eventFilter__actions [data-action="lite"]'          : 'addQuery'
    'click .eventFilter__actions [data-action="advanced"]'      : 'addQuery'

  childViewContainer: "#tm-events-tabs"

  template: "events/content"

  config:
    initialTab: "list"

    childViewTemplate: "events/tab_item"

    tabs: [
        label: ''
        name: "list"
      ,
        label: ''
        name: "table"
    ]

  getSelectedQuery: ->
    @ui.selections.select2('data')

  setQuery: (query) ->
    @ui.selections.select2('data', {id: query.id, text: query.get('DISPLAY_NAME')})

  blockObjectsToolbar: ->
    @ui.objects_toolbar_set_tag.prop("disabled", true)
    @ui.objects_toolbar_export.prop("disabled", true)
    @ui.objects_toolbar_set_decision.prop("disabled", true)
    @ui.objects_toolbar_debug.prop("disabled", true)

  blockToolbar: ->
    @ui.toolbar_create.prop("disabled", true)
    @ui.toolbar_edit.prop("disabled", true)
    @ui.toolbar_copy.prop("disabled", true)
    @ui.toolbar_delete.prop("disabled", true)
    @ui.toolbar_execute.prop("disabled", true)

  update_objects_toolbar: (selected) ->

    @blockObjectsToolbar()

    query = @getSelectedQuery()

    if query and @eventsCollection.length and helpers.can({action: 'export', type: 'event'})
      @ui.objects_toolbar_export.prop("disabled", false)

    if selected
      if helpers.can({action: 'edit_tag', type: 'event'})
        @ui.objects_toolbar_set_tag.prop("disabled", false)
      if helpers.can({action: 'edit_user_decision', type: 'event'})
        @ui.objects_toolbar_set_decision.prop("disabled", false)

      @ui.objects_toolbar_debug.prop("disabled", false)

  update_selection_toolbar: ->

    @blockToolbar()

    if helpers.can({action: 'edit', type: 'query'})
      @ui.toolbar_create.prop("disabled", false)

    query = @getSelectedQuery()

    if query
      @selections_collection.fetchOne query.id, {}, (query) =>
        return if (query.get 'USER_ID' isnt App.Session.currentUser().get('USER_ID')) and (query.get 'IS_PERSONAL' is 1)

        if not (query.id of App.EventsConditionsManager.Events)
          if helpers.can({action: 'edit', type: 'query'})
            @ui.toolbar_edit.prop("disabled", false)
            @ui.toolbar_copy.prop("disabled", false)

          if helpers.can({action: 'delete', type: 'query'})
            @ui.toolbar_delete.prop("disabled", false)

          if helpers.can({action: 'show', type: 'query'})
            @ui.toolbar_execute.prop("disabled", false)

  addQuery: (e) ->
    e.preventDefault()

    @trigger 'add_query', $(e.currentTarget).data('action')

  setDecision: (e) =>
    e.preventDefault()

    @trigger 'setDecision', $(e.currentTarget).data('decision')

  onShow: ->
    super

    @regions.paginator.show @events_paginator_

    @ui.selections.select2
      allowClear: true
      placeholder: App.t 'events.selection.selection_query_placeholder'
      formatResult: (result, container, query, escapeMarkup) ->
        if result.id
          return "<div>#{result.text}</div><div class='selection__owner'>#{result.user}</div>"
        else
          return $.fn.select2.defaults.formatResult(result, container, query, escapeMarkup)
      query: (query) =>
        @selections_collection.perPage = 1000
        @selections_collection.fetch
          reset: true
          success: (collection, response, options) ->
            if query.term is ''
              data = collection
            else
              data = collection.filter (selection) ->
                selection.get('DISPLAY_NAME').toUpperCase().indexOf(query.term.toUpperCase())>=0


            if data.length
              results = [
                text: App.t('events.selection.selection_group'),
                children: data.map (selection) ->
                  {
                    id: selection.get('QUERY_ID')
                    text: selection.get('DISPLAY_NAME')
                    user: selection.get('user')?.DISPLAY_NAME
                  }
              ]
            else
              results = []

            query.callback
              more: false
              results: results
    .on "select2-removed", (e) =>
      @trigger 'query:unset'

    .on 'change', (e) =>
      @update_selection_toolbar()
      @update_objects_toolbar()

      @trigger 'query:select', $('.selections').select2('data')

    @update_selection_toolbar()
    @update_objects_toolbar()

    @listenTo @, 'after:tab_changed', => @update_objects_toolbar()

  initialize: (options) ->
    super(@config)

    services = App.request 'bookworm', 'service'

    @selections_collection = options.selections_collection
    @eventsCollection = options.eventsCollection

    listView = new EventsListView
      collection: @eventsCollection
      services: services
    tableView = new EventsTableView
      collection: @eventsCollection
      services: services

    @listenTo listView, 'childview:objectSelected', (view) ->
      @update_objects_toolbar view.model
      @trigger 'event:selected', view.model

    @listenTo tableView, 'childview:objectSelected', (selected) ->
      @update_objects_toolbar selected
      @trigger 'event:selected', selected

    @listenTo listView, 'childview:tag__delete', (view, tags) =>
      @trigger 'delete-tag', view.model, tags


    # Добавляем вьюхи
    @addView listView, "list"
    @addView tableView, 'table'

    @events_paginator_ = new App.Views.Controls.Paginator
      collection: @eventsCollection
      showPageSize: true

    @listenTo @selections_collection, 'add', =>
      @update_selection_toolbar()


    @listenTo @eventsCollection, 'reset', =>
      @ui.selectionDate.hide()
      @ui.eventsCount.hide()

      query = @getSelectedQuery()

      if query
        @selections_collection.fetchOne query.id, {refetch: true}, @updateQueryCompleteDate

      events_limit = App.Setting.get 'query_stop_count'

      if @eventsCollection.total_count >= events_limit
        cnt = App.t 'events.events.events_count_limit', limit: events_limit
      else
        cnt = @eventsCollection.total_count

      @ui.eventsCount.show()
      @ui.query_events_count.html cnt

      @update_selection_toolbar()

    @listenTo @selections_collection, 'remove', (model, collection, options) =>
      query = @getSelectedQuery()

      # Если удалили выбранный запрос - очищаем select2
      if query.id is model.id
        @ui.selections.select2('val', '')

        @update_selection_toolbar()

  updateQueryCompleteDate: (query) =>
    co =>
      if not (query instanceof Backbone.Model)
        query = new Selection.model QUERY_ID: query
        yield query.fetch()

      if query.get('status')
        complete_date = moment.utc(query.get('status').COMPLETE_DATE)
        @ui.query_complete_date.html complete_date.local().format('L LT')
        @ui.selectionDate.show()

