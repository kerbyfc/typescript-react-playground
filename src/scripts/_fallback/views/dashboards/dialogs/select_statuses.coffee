"use strict"

require "models/lists/statuses.coffee"
require "bootstrap"

App.module "Dashboards",
  startWithParent: true
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards ?= {}

    class App.Views.Dashboards.SelectStatusDialog extends Marionette.LayoutView

      template: "dashboards/dialogs/select_statuses"

      regions:
        statuses_table             : "#statuses_table"
        statuses_paginator           : "#statuses_paginator"

      events:
        "click .-success": "save"

      initialize: (options) ->
        @callback = options.callback
        @title = options.title
        @selected_person_statuses = options.selected ? []
        @statuses_to_delete = []
        @statuses_to_add = []

        @collection = new App.Models.Lists.IdentityStatuses()

        @collection.config =
          _CONFIG_: "ACTIVE"

        @statuses_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @statuses_table_ = new App.Views.Controls.TableView
          collection: @collection
          config:
            default:
              checkbox: true
              sortCol: "DISPLAY_NAME"
            columns: [
              {
                id      : "DISPLAY_NAME"
                name    : App.t 'lists.statuses.display_name_column'
                field   : "DISPLAY_NAME"
                resizable : true
                sortable  : true
                minWidth  : 150
                formatter : (row, cell, value, columnDef, dataContext) ->
                  if App.t('lists.statuses', { returnObjectTrees: true })[dataContext.get(columnDef.field)]
                    App.t('lists.statuses', { returnObjectTrees: true })[dataContext.get(columnDef.field)]
                  else
                    dataContext.get(columnDef.field)
              }
              {
                id      : "NOTE"
                name    : App.t 'lists.statuses.note_column'
                resizable : true
                sortable  : true
                minWidth  : 150
                field   : "NOTE"
                formatter : (row, cell, value, columnDef, dataContext) ->
                  locale = App.t("lists.statuses", { returnObjectTrees: true })
                  if dataContext.get(columnDef.field) and dataContext.get(columnDef.field).charAt(0) is '_' and
                  dataContext.get(columnDef.field).charAt(dataContext.get(columnDef.field).length - 1) is '_'
                    locale[dataContext.get(columnDef.field) + "note"]
                  else
                    dataContext.get(columnDef.field)
              }
            ]


      save: (e) ->
        e.preventDefault()

        @selected_statuses_ = @statuses_table_.getSelectedModels()

        @statuses_to_delete = _.union (_.difference @selected_statuses, @selected_statuses_), @statuses_to_delete
        @statuses_to_add = _.union (_.difference @selected_statuses_, @selected_statuses), @statuses_to_add

        @callback @statuses_to_add, @statuses_to_delete

        @destroy()

      onShow: ->
        @$el.i18n()

        # Рендерим контролы
        @statuses_table.show @statuses_table_

        @statuses_paginator.show @statuses_paginator_

        @statuses_table_.resize 300, 600

        @collection.on 'reset', (collection, options) =>

          if @selected_person_statuses.length isnt 0
            # Получаем теги для объектов
            @selected_statuses = _.map @selected_person_statuses, (status) ->
              collection.get(status)

          # Отсеиваем дубликаты
          @selected_statuses = _.compact(_.unique @selected_statuses)

          # Селектим выбранные статусы
          @statuses_table_.setSelectedRows @selected_statuses

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', (collection, xhr, options) ->
            @selected_statuses_ = @statuses_table_.getSelectedModels()

            @statuses_to_delete = _.union (_.difference @selected_statuses, @selected_statuses_), @statuses_to_delete
            @statuses_to_add = _.union (_.difference @selected_statuses_, @selected_statuses), @statuses_to_add


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
