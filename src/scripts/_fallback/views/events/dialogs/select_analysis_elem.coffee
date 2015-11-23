"use strict"

require "bootstrap"

App.module "Events.Dialogs",
  startWithParent: true
  define: (Events, App, Backbone, Marionette, $) ->

    App.Views.Events ?= {}

    class App.Views.Events.SelectElemDialog extends Marionette.LayoutView

      template: "events/dialogs/select_elems"

      regions:
        elems_table           : "#elems_table"
        elems_paginator         : "#elems_paginator"

      initialize: (options) ->
        @elems_to_delete = []
        @elems_to_add = []

        @collection.config =
          _CONFIG_: "ACTIVE"

      save: ->
        @selected_elems_ = _.union @selected_elems_, @elems_table_.getSelectedModels()

        @elems_to_delete = _.union (_.difference @selected_elems, @selected_elems_), @elems_to_delete
        @elems_to_add = _.union (_.difference @selected_elems_, @selected_elems), @elems_to_add

        [@elems_to_add, @elems_to_delete]

      onShow: ->
        @elems_paginator_ = new App.Views.Controls.Paginator
          collection: @collection

        @elems_table_ = new App.Views.Controls.TableView
          collection: @collection
          config: @options.table_config

        # Рендерим контролы
        @elems_table.show @elems_table_

        @elems_paginator.show @elems_paginator_

        @elems_table_.resize 300, 880

        @listenTo @elems_table_, "table:sort", _.bind(@collection.sortCollection, @collection)

        @collection.on 'reset', (collection) =>
          if @selected.length isnt 0
            @selected_elems = _.map @selected, (elem) ->
              collection.get(elem.split(':')[1])

          # Отсеиваем дубликаты
          @selected_elems = _.compact(_.unique @selected_elems)

          # Селектим выбранные
          @elems_table_.setSelectedRows @selected_elems

        @collection.sortRule = sort:
          'DISPLAY_NAME' : 'asc'

        throttled = _.throttle =>
          val = @$('[data-action="search"]').val()

          if val isnt ''
            if val.charAt(0) isnt '*'
              val = "*#{val}"

            if val.charAt(val.length-1) isnt '*'
              val = val + '*'

            @collection.currentPage = 0
            @collection.fetch
              data:
                filter:
                  DISPLAY_NAME: "#{val}"
              reset: true
          else
            @collection.fetch
              reset: true
        , 777

        @$('[data-action="search"]').keyup throttled

        @collection.fetch
          reset: true
          wait: true
          success: =>
            @collection.on 'request', =>
              @selected_elems_ = _.union @selected_elems_, @elems_table_.getSelectedModels()

              @elems_to_delete = _.union (_.difference @selected_elems, @selected_elems_), @elems_to_delete
              @elems_to_add = _.union (_.difference @selected_elems_, @selected_elems), @elems_to_add


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
