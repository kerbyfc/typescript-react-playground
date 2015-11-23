"use strict"

require "multiselect"

module.exports = class AdvancedQueryParams extends Marionette.ItemView

  template: 'events/query_builder/query_advanced_params'

  ui:
    list            : '[data-id="pre-selected-options"]'
    sort_field      : '[name="SORT_FIELD"]'
    sort_direction  : '[name="SORT_DIRECTION"]'


  behaviors: ->
    data = {}
    condition = @options.model.get('QUERY')

    sort_field = Object.keys(condition.sort)[0]
    sort_direction = condition.sort[sort_field]

    if sort_field is 'RELEVANCE'
      data['SORT_FIELD'] = 'text'
    else
      data['SORT_FIELD'] = sort_field

    data['SORT_DIRECTION'] = sort_direction

    Form:
      syphon : data

  _findTextCondition: (conditions) ->
    _.reduce conditions, (result, condition) =>
      if condition.children
        return result or @_findTextCondition condition.children
      else
        if condition.category is 'text'
          return result or true
        else
          return result or false
    , false

  _checkIsText: (val, reset = false) ->
    if val in ['text', 'RELEVANCE']
      @ui.sort_direction.select2 'enable', false
      @ui.sort_direction.select2 "data",
        id: 'asc'
        text: App.t 'events.conditions.text_sort_value'
        element: @ui.sort_direction
    else
      if reset
        @ui.sort_direction.select2('enable', true)
        @ui.sort_direction.select2('val', 'desc')

  _triggerTextCondition: (condition) ->
    $text_option  = @$('option[value="text"]')

    if not @_findTextCondition [condition]
      $text_option.prop 'disabled', true
    else
      $text_option.prop 'disabled', false

  onShow: ->
    @listenTo @, 'behavior:Form:onShow', =>
      condition = @model.get('QUERY')

      @_triggerTextCondition(condition.data)

      sort_field = Object.keys(condition.sort)[0]
      @_checkIsText(sort_field)

      @ui.sort_field.select2()
      .on 'change', (e) =>
        val = $(e.currentTarget).val()

        @_checkIsText(val, true)

    @ui.list.multiSelect
      selectableHeader: "<div class='event__columns-header'>#{App.t 'events.conditions.sort_available_header'}</div>"
      selectionHeader: "<div class='event__columns-header'>#{App.t 'events.conditions.sort_displayed_header'}</div>"

    @$el.find("div.ms-selection ul.ms-list").sortable().disableSelection()

    columns = @model.get('QUERY').columns
    if columns
      if columns.length
        @ui.list.multiSelect('select', columns)
      else
        @ui.list.multiSelect('select_all')

    @listenTo @, "form:change", _.debounce =>
      data = @getData()

      sort = {}
      if data.SORT_FIELD is 'text'
        sort['RELEVANCE'] = 'desc'
      else
        sort[data.SORT_FIELD] = data.SORT_DIRECTION

      # Клонируем данные иначе не произойдет изменение модели
      condition = _.clone @model.get('QUERY')
      condition.sort = sort
      condition.columns = data.columns

      @model.set 'QUERY', condition
    , 333

    @listenTo @model, 'change', =>
      condition = @model.get('QUERY').data

      if @ui.sort_field.val() is 'text'
        if not @_findTextCondition [condition]
          @ui.sort_field.select2('val', 'CAPTURE_DATE')
          @ui.sort_direction.select2('enable', true)
          @ui.sort_direction.select2('val', 'desc')

      @_triggerTextCondition(condition)
