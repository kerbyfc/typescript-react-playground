"use strict"

require "models/entry.coffee"
require "bootstrap"

App.module "Events.Dialogs",
  startWithParent: true
  define: (Events, App, Backbone, Marionette, $) ->

    App.Views.Events ?= {}

    class App.Views.Events.SelectPersonDialog extends Marionette.LayoutView

      template: "events/dialogs/select_persons"

      regions:
        persons_table           : "#persons_table"
        persons_paginator         : "#persons_paginator"

      initialize: (options) ->
        @persons_to_delete = []
        @persons_to_add = []

        @collection = new App.Models.Entry.Person()

        @collection.config =
          _CONFIG_: "ACTIVE"

        @persons_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @persons_table_ = new App.Views.Controls.TableView
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
        @selected_persons_ = _.union @selected_persons_, @persons_table_.getSelectedModels()

        @persons_to_delete = _.union (_.difference @selected_persons, @selected_persons_), @persons_to_delete
        @persons_to_add = _.union (_.difference @selected_persons_, @selected_persons), @persons_to_add

        [@persons_to_add, @persons_to_delete]

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
        @persons_table.show @persons_table_

        @persons_paginator.show @persons_paginator_

        @persons_table_.resize 300, 800

        @listenTo @persons_table_, "table:sort", @onSort

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
            @selected_persons = _.map @selected, (person) ->
              collection.get(person.split(':')[1])

          # Отсеиваем дубликаты
          @selected_persons = _.compact(_.unique @selected_persons)

          # Селектим выбранные теги
          @persons_table_.setSelectedRows @selected_persons

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', (collection, xhr, options) =>
              @selected_persons_ = _.union @selected_persons_, @persons_table_.getSelectedModels()

              @persons_to_delete = _.union (_.difference @selected_persons, @selected_persons_), @persons_to_delete
              @persons_to_add = _.union (_.difference @selected_persons_, @selected_persons), @persons_to_add


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
