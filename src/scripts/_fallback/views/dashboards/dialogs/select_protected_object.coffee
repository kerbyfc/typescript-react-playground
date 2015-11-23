"use strict"

require "bootstrap"
require "models/protected/document.coffee"

App.module "Dashboards",
  startWithParent: true
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards ?= {}

    class App.Views.Dashboards.SelectProtectedDocumentDialog extends Marionette.LayoutView

      template: "dashboards/dialogs/select_statuses"

      regions:
        documents_table            : "#statuses_table"
        documents_paginator          : "#statuses_paginator"

      events:
        "click .-success": "save"

      initialize: (options) ->
        @callback = options.callback
        @title = options.title
        @selected_protected_documents = options.selected ? []
        @selected_protected_documents_ = []

        @collection = new App.Models.Protected.Documents

        @collection.config =
          _CONFIG_: "ACTIVE"

        @statuses_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @documents_table_ = new App.Views.Controls.TableView
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
              }
              {
                id      : "NOTE"
                name    : App.t 'lists.statuses.note_column'
                resizable : true
                sortable  : true
                minWidth  : 150
                field   : "NOTE"
              }
            ]


      save: (e) ->
        e.preventDefault()

        @selected_protected_documents_ = _.union @selected_protected_documents_, @documents_table_.getSelectedModels()

        @callback @selected_protected_documents_

        @destroy()

      onShow: ->
        @$el.i18n()

        # Рендерим контролы
        @documents_table.show @documents_table_

        @documents_paginator.show @statuses_paginator_

        @documents_table_.resize 300, 600

        @collection.on 'reset', (collection, options) =>

          if @selected_protected_documents.length isnt 0
            # Получаем теги для объектов
            @selected_protected_documents = _.map @selected_protected_documents, (document) ->
              collection.get(document)

          # Отсеиваем дубликаты
          @selected_protected_documents = _.compact(_.unique @selected_protected_documents)

          # Селектим выбранные статусы
          @documents_table_.setSelectedRows @selected_protected_documents

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', (collection, xhr, options) ->
              @selected_protected_documents_ = _.union @selected_protected_documents_, @documents_table_.getSelectedModels()


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
