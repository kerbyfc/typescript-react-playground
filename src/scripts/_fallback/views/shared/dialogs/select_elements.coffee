App.module "Application.Common",
  startWithParent: true
  define: (Common, App, Backbone, Marionette, $) ->

    App.Views.Common ?= {}
    App.Views.Common.Dialogs ?= {}

    class App.Views.Common.Dialogs.SelectElementsDialog extends Marionette.LayoutView

      getTemplate: ->

        if @options?.template then return @options.template

        if @type is 'dialog'
          "shared/dialogs/select_elements_dialog.ect.html"
        else
          "shared/dialogs/select_elements.ect.html"

      regions:
        elements_table     : "#elements_table"
        elements_paginator : "#elements_paginator"

      events:
        "click [data-success]": "save"

      initialize: (options) ->
        @type = options.type or 'dialog'
        @callback = options.callback
        @title = options.title
        if options.selected
          @selected = options.selected
        @elements_to_delete = []
        @elements_to_add = []

        config =
          default:
            checkbox: true

        @elements_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @elements_table_ = new App.Views.Controls.TableView
          collection: @collection
          config: _.merge config, options.table_config

      save: (e) ->
        e?.preventDefault()

        if @type is 'dialog'
          # Пробуем серилиазовать данные

          try
            data = Backbone.Syphon.serialize(@)
          catch
            null

        @selected_elements_ = @elements_table_.getSelectedModels()
        @indeterminate_elements_ = @elements_table_.getIndeterminateCheckboxesModels()

        @elements_to_add = _.union (_.difference @selected_elements_, @selected_elements), @elements_to_add

        @elements_to_delete = _.union (_.difference @selected_elements, @selected_elements_), @elements_to_delete
        @elements_to_delete = _.union(
          _.difference(
            _.difference @indeterminate_elements, @indeterminate_elements_
            @elements_to_add
          )
          @elements_to_delete
        )

        if @type is 'dialog'
          @callback(@elements_to_add, @elements_to_delete, data) if @callback

          @destroy()
        else
          [@elements_to_add, @elements_to_delete]

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

        @elements_table_.resize 300, 800

        @listenTo @elements_table_, "table:sort", @onSort

        throttled = _.throttle =>
          val = @$('[data-action="search"]').val()

          @collection.search val
        , 777

        @$('[data-action="search"]').keyup throttled

        @collection.on 'reset', (collection, options) =>

          if @selected and @selected.length isnt 0

            @selected_elements =
              _.compact(
                _.map(
                  _.uniq @selected
                  (element) ->
                    collection.get(element)
                )
              )

            @indeterminate_elements =
              _.compact(
                _.map(
                  _.difference(
                    @selected
                    _.map(
                      @selected_elements
                      (model) ->
                        model.id
                    )
                  )
                  (element) ->
                    collection.get(element)
                )
              )

            # Селектим статусы всех персон
            @elements_table_.setSelectedRows @selected_elements

            # Селектим статусы некоторых персон
            @elements_table_.setIndeterminateCheckboxes @indeterminate_elements

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', (collection, xhr, options) =>
              @selected_elements_ = @elements_table_.getSelectedModels()

              @elements_to_delete = _.union (_.difference @selected_elements, @selected_elements_), @elements_to_delete
              @elements_to_add = _.union (_.difference @selected_elements_, @selected_elements), @elements_to_add


      serializeData: ->
        data = Marionette.LayoutView::serializeData.apply @, arguments

        # Добавляем название диалога
        data.modal_dialog_title = @title

        data
