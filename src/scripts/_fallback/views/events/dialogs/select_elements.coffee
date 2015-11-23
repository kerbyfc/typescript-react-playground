"use strict"

module.exports = class SelectElementsDialog extends Marionette.LayoutView

  template: "events/dialogs/select_elements"

  regions:
    elements_table             : "#elements_table"
    elements_paginator           : "#elements_paginator"

  events:
    "click [data-action='save']"     : "save"

  templateHelpers: ->
    title: @options.title

  initialize: (options) ->
    @callback = options.callback
    @selected_elements = options.selected ? []
    @elements_to_delete = []
    @elements_to_add = []

    @collection.config =
      _CONFIG_: "ACTIVE"

    @elements_paginator_ = new App.Views.Controls.Paginator
      collection: @collection

    @elements_table_ = new App.Views.Controls.TableView
      collection: @collection
      config: options.table_config

  save: (e) ->
    e?.preventDefault()

    @selected_elements_ = @elements_table_.getSelectedModels()

    if @selected_elements.length isnt 0
      @elements_to_delete = _.union (_.difference @selected_elements, @selected_elements_), @elements_to_delete

    @elements_to_add = _.union (_.difference @selected_elements_, @selected_elements), @elements_to_add

    @callback(@elements_to_add, @elements_to_delete) if @callback

    @destroy()

  onSort: (args) ->
    # Формируем параметры запроса
    data = {}
    data[args.field] = args.direction

    @collection.sortRule = data

    @collection.fetch
      reset: true

  onShow: ->
    # Рендерим контролы
    @elements_table.show @elements_table_

    @elements_paginator.show @elements_paginator_

    @elements_table_.resize 300, 600

    @listenTo @elements_table_, "table:sort", @onSort

    throttled = _.throttle =>
      val = @$('[data-action="search"]').val()

      if val isnt ''

        @collection.currentPage = 0
        @collection.fetch
          data:
            filter:
              DISPLAY_NAME: "#{val}*"
          reset: true
      else
        @collection.fetch
          reset: true
    , 777

    @$('[data-action="search"]').keyup throttled

    @collection.on 'reset', (collection, options) =>

      if @selected_elements.length isnt 0

        @selected_elements = _.map @selected_elements, (element) ->
          collection.get(element)

      # Отсеиваем дубликаты
      @selected_elements = _.compact(_.unique @selected_elements)

      # Селектим выбранные теги
      @elements_table_.setSelectedRows @selected_elements

    @collection.fetch
      reset: true
      wait: true
      success: =>
        @collection.on 'request', (collection, xhr, options) =>
          @selected_elements_ = @elements_table_.getSelectedModels()

          if @selected_elements.length isnt 0
            @elements_to_delete = _.union (_.difference @selected_elements, @selected_elements_), @elements_to_delete
          @elements_to_add = _.union (_.difference @selected_elements_, @selected_elements), @elements_to_add
