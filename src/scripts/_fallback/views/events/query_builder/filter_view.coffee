"use strict"

require "bootstrap"
require "views/events/dialogs/select_elements.coffee"

QueryBuilderBase = require "views/events/query_builder/query_builder_base.coffee"

conditions = require "settings/conditions"

module.exports = class FilterView extends App.Helpers.virtual_class(
  QueryBuilderBase
  Backbone.Marionette.CompositeView
)

  tagName: "div"

  childView: FilterView

  events:
    "click .queryBuilder__remove"       : "deleteCondition"
    "click .conditions__fake-link"      : "changeLink"

  defaults:
    conditions: conditions

  templateHelpers: ->
    model = @options.model

    category = if model.get('category') is 'object_header'
      model.get('value').name
    else
      model.get 'category'

    mode                    : @options.link_operator
    filterName              : category
    tpl                     : category
    conditions              : @options.conditions or conditions
    exclude                 : @options.exclude or []

  childViewOptions: ->
    if @model.has('children')
      return {
        link_operator : @model.get 'link_operator'
        formats       : @formats
        afterRender   : @options.afterRender
      }

  behaviors: ->
    behaviors = {}

    if not @options.model.has 'link_operator'
      @data = {}

      @data = @parseQuery([@options.model.toJSON()])

      behaviors = _.merge behaviors,
        Form:
          listen : @options.model
          syphon : @data

    return behaviors

  getTemplate: ->
    if @model and @model.has('children')
      return "events/query_builder/block"
    else
      return "events/query_builder/condition_item"

  _update: (view, model, index, sourceCollection, destCollection) ->
    if sourceCollection
      sourceCollection.remove(model)

    destCollection.add model,
      at: index

  deleteCondition: ->
    @model.destroy()

  initialize: (options = {}) ->
    @formats = options.formats
    _.extend @options, _.defaults options, @defaults
    if @model and @model.has('children')
      @collection = @model.children

  _addCondition: (model, category) ->
    switch category
      when 'block'
        model.children.add new model.children.model
          link_operator: 'and'
          children: []
      else
        model.children.add new model.children.model
          category: category
          value: null

  resetError: ->
    @$el.find "[data-error]"
    .removeAttr 'data-error'

    #TODO: у Дениса неверно ресетится форма?
    @$el.find("[data-error-message='#{@cid}']")
    .remove()

  onShow: ->
    model = @model

    if model.has('children')
      @$el.addClass('queryBuilder__block')

      @$el.find('> footer [name="add_condition"]').select2
        placeholder: App.t 'events.conditions.add_condition',
        allowClear: true
      .on 'select2-selecting', (e) =>
        e.preventDefault()

        @$el.find('select').select2('close')

        @_addCondition(model, e.val)
    else
      @$el.addClass('queryBuilder__item')

      @listenTo @, "form:change", _.debounce =>
        data = @getData()

        model.set model.createModelData _.keys(data)[0], data[_.keys(data)[0]]
        @resetError()
        model.isValid()
      , 333

    @$el.on 'click', '> div > .queryBuilder__link', =>
      if model.get('link_operator') is 'and'
        model.set('link_operator', 'or')
      else
        model.set('link_operator', 'and')

      @children.each (view) ->
        view.options.link_operator = model.get 'link_operator'
        view._setLink()

  attachBuffer: (compositeView) ->
    $container = @getChildViewContainer(compositeView).children('footer')

    $container.before(@_createBuffer(compositeView))

  _insertAfter: (childView) ->
    $container = @getChildViewContainer(@, childView).children('footer')
    $container.before(childView.el)

  _setLink: ->
    @$el.attr('data-content', @options.link_operator)

  onAddChild: (childView) ->
    if childView.model.get('category') in [
      'capture_date'
      'destination_type'
      'verdict'
      'user_decision'
      'violation_level'
      'workstation_type'
      'object_type_code'
      'protocol'
    ]
      childView.trigger 'form:change'

  onRender: ->
    model = @model

    @_setLink()
    @$el.attr('data-id', model.cid)

    if @model.has('children')
      @$el.sortable
        connectWith: ".queryBuilder__block"
        placeholder:
          element: (currentItem) ->
            return $("<div class='queryBuilder__spot queryBuilder__item' data-content='#{model.get('link_operator')}'></div>")

          update: (container, p) ->
            return
        handle: '.queryBuilder__name'
        forcePlaceholderSize: true
        forceHelperSize: true
        items: '> div'
        helper: 'clone'

        start: (event, ui) =>
          event.stopPropagation()

          # Сохраняем коллекцию источника
          ui.item.collection = @collection
          ui.item.model = @collection.get ui.item.attr('data-id')

        receive: (event, ui) =>
          event.stopPropagation()

          @_update(@, ui.item.model, ui.item.index() - 3, ui.item.collection, @collection)

        stop: (event, ui) =>
          event.stopPropagation()

          if event.target is ui.item.parent()[0]
            @_update(@, ui.item.model, ui.item.index() - 3, @collection, @collection)

            $(event.target).sortable( "refresh" )

      .disableSelection()
