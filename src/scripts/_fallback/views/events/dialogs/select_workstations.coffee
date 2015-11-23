"use strict"

require "models/entry.coffee"

App.module "Events.Dialogs",
  startWithParent: true
  define: (Events, App, Backbone, Marionette, $) ->

    App.Views.Events ?= {}

    class App.Views.Events.SelectWorkstationsDialog extends Marionette.LayoutView

      template: "events/dialogs/select_workstations"

      regions:
        workstations_table             : "#workstations_table"
        workstations_paginator           : "#workstations_paginator"

      events:
        "click .-success": "save"

      initialize: (options) ->
        @workstations_to_delete = []
        @workstations_to_add = []
        @selected = _.compact options?.selected
        @callback = options.callback
        @title = options.title

        @collection = new App.Models.Entry.Workstation

        @collection.config =
          _CONFIG_: "ACTIVE"

        @workstations_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @workstations_table_ = new App.Views.Controls.TableView
          collection: @collection
          config:
            default:
              checkbox: true
              sortCol: "DISPLAY_NAME"
            columns: [
              {
                id      : "DISPLAY_NAME"
                name    : App.t 'lists.tags.display_name_column'
                field   : "DISPLAY_NAME"
                resizable : true
                sortable  : true
                minWidth  : 150
              }
              {
                id      : "SERVER_NAME"
                name    : App.t 'settings.ldap_settings.display_name'
                resizable : true
                sortable  : true
                minWidth  : 100
                cssClass  : "center"
                field   : "SERVER_NAME"
              }
              {
                id      : "SOURCE"
                name    : App.t 'events.events.source'
                resizable : true
                sortable  : true
                minWidth  : 80
                cssClass  : "center"
                field   : "SOURCE"
                formatter     : (row, cell, value, columnDef, dataContext) ->
                  return dataContext.get(columnDef.field).toUpperCase()
              }
              {
                id      : "NOTE"
                name    : App.t 'lists.tags.note_column'
                resizable : true
                sortable  : true
                minWidth  : 150
                field   : "NOTE"
              }
            ]


      save: ->
        @selected_workstations_ = _.union @selected_workstations_, @workstations_table_.getSelectedModels()

        @workstations_to_delete = _.union (_.difference @selected_workstations, @selected_workstations_), @workstations_to_delete
        @workstations_to_add = _.union (_.difference @selected_workstations_, @selected_workstations), @workstations_to_add

        workstations_to_add = _.map @workstations_to_add, (workstation) ->
          "workstation:#{workstation.get('WORKSTATION_ID')}:#{workstation.get('DISPLAY_NAME')}"

        workstations_to_delete = _.map @workstations_to_delete, (workstation) ->
          "workstation:#{workstation.get('WORKSTATION_ID')}:#{workstation.get('DISPLAY_NAME')}"

        @callback(workstations_to_add, workstations_to_delete)

        @destroy()

      onSort: (args) ->
        # Формируем параметры запроса
        data = {}
        data.sort = {}
        data.sort[args.field] = args.direction

        @collection.sortRule = data

        @collection.fetch
          reset: true

      onShow: ->
        # Рендерим контролы
        @workstations_table.show @workstations_table_

        @workstations_paginator.show @workstations_paginator_

        @workstations_table_.resize 300, 800

        @listenTo @workstations_table_, "table:sort", @onSort

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
          if @selected.length isnt 0
            # Получаем теги для объектов
            @selected_workstations = _.map @selected, (workstation) ->
              collection.get(workstation.split(':')[1])

          # Отсеиваем дубликаты
          @selected_workstations = _.compact(_.unique @selected_workstations)

          # Селектим выбранные теги
          @workstations_table_.setSelectedRows @selected_workstations

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', (collection, xhr, options) =>
              @selected_workstations_ = _.union @selected_workstations_, @workstations_table_.getSelectedModels()

              @workstations_to_delete = _.union (_.difference @selected_workstations, @selected_workstations_),
                              @workstations_to_delete
              @workstations_to_add = _.union (_.difference @selected_workstations_, @selected_workstations),
                              @workstations_to_add


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
