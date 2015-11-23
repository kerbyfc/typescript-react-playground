"use strict"

require "jquery.scrollTo"

require "views/controls/paginator.coffee"
require "behaviors/events/entity_info.coffee"

ResourceGroups = require "models/lists/resourceGroups.coffee"
CollapseBehavior = require "behaviors/events/collapse.coffee"


class EmptyEventView extends Marionette.ItemView

  template: "events/empty_event"

  className: 'event__empty'

class EventView extends Marionette.ItemView

  template: "events/event"

  className: 'eventItem'

  behaviors:
    EntityInfo:
      targets       : '.popover_info'
      behaviorClass : App.Behaviors.Events.EntityInfo
    Collapse:
      behaviorClass: CollapseBehavior

  templateHelpers: ->
    service: @service
    resourceGroups: @options.resourceGroups
    formats: @options.formats

  events:
    'click'                 : 'onClick'
    "click .tag__delete"    : "tag__delete"

  onClick: (e) ->
    @trigger 'objectSelected', @

  "tag__delete": (e) ->
    e.preventDefault()
    e.stopPropagation()

    @trigger "tag__delete", [$(e.currentTarget).data('tag-id')]

  deleteActiveClass: ->
    @$el.removeClass "selected"

  initialize: (options) ->
    @service = options.services.get(@model.get('SERVICE_CODE'))

    @listenTo @model, 'change', @render


module.exports = class EventsList extends Marionette.CollectionView

  childView: EventView

  className: 'event__list'

  emptyView: EmptyEventView

  childViewOptions: (model, index) ->
    return {
      services: @services
      resourceGroups: @resourceGroups
      formats: @formats
    }

  initialize: (options) ->
    {@collection, @services} = options
    @resourceGroups = new ResourceGroups.ListCollection type: 'query'
    @formats = App.request('bookworm', 'fileformat').pretty()

    # ToDo: Сделать для пагинированных коллекций метод fetchAll
    @resourceGroups.paginator_ui.perPage = 100
    @resourceGroups.fetch
      async: false

  getSelected: ->
    views = @children.filter (event) ->
      event.$el.hasClass("selected")

    _.map views, (view) ->
      view.model

  _changeActiveView: (index) =>
    @collection.selected = @collection.at (index)

    itemView = @children.findByModel(@collection.selected)

    # Скроллим на нужный обьект
    @$el.closest('._scrollable').scrollTo itemView.$el

    itemView.trigger 'objectSelected', itemView

  onShow: ->
    Mousetrap.bind 'up', =>
      if @collection.length
        index = @collection.indexOf(@collection.selected)
        if index
          throttled = _.throttle @_changeActiveView, 777
          throttled(index - 1)

    Mousetrap.bind 'down', =>
      if @collection.length
        index = @collection.indexOf(@collection.selected)
        if index < @collection.length - 1
          throttled = _.throttle @_changeActiveView, 777
          throttled(index + 1)

    @listenTo @collection, 'reset', =>
      @$el.closest('._scrollable').scrollTop 0

      if @collection.length
        @trigger 'childview:objectSelected', @children.findByIndex(0)

    @listenTo @, 'childview:objectSelected', (view, options) =>
      @collection.selected = view.model
      @children.call 'deleteActiveClass'
      view.$el.addClass("selected")
