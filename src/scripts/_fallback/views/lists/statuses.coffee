"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"

module.exports = class IdentityStatusesView extends Marionette.LayoutView

  template: "lists/statuses"

  className: 'content'

  regions:
    statuses_table     : "#statuses_table"
    statuses_paginator : "#statuses_paginator"

  ui:
    statuses_tb_create          : ".toolbar [data-action='create_status']"
    statuses_tb_edit            : ".toolbar [data-action='edit_status']"
    statuses_tb_delete          : ".toolbar [data-action='delete_status']"
    statuses_tb_create_policy   : ".toolbar [data-action='create_policy']"

  triggers:
    "click .toolbar [data-action='create_status']" : "create"
    "click .toolbar [data-action='edit_status']"   : "edit"
    "click .toolbar [data-action='delete_status']" : "delete"
    "click .toolbar [data-action='create_policy']" : "create_policy"

  initialize: ->
    @statuses_paginator_ = new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: true

    @statuses_table_ = new App.Views.Controls.TableView
      collection: @collection
      config:
        name: 'statusesTable'
        default:
          sortCol: "DISPLAY_NAME"
        columns: [
          id      : "COLOR"
          name    : ""
          menuName  : App.t 'lists.statuses.color'
          field   : "COLOR"
          width   : 40
          resizable : false
          sortable  : true
          cssClass  : "center"
          formatter : (row, cell, value, columnDef, dataContext) ->
            "<div class='tag__color' data-color='#{dataContext.get(columnDef.field)}'></div>"
        ,
          id      : "DISPLAY_NAME"
          name    : App.t 'lists.statuses.display_name'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 150
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "NOTE"
          name    : App.t 'lists.statuses.note'
          resizable : true
          sortable  : true
          minWidth  : 150
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]

    @statuses_table_.onCellCanEdit = (args) ->
      if args.item.get('EDITABLE') is 0 or
         helpers.islock({type: 'status', action: 'edit'})
        return false

      return true

  block_statuses_toolbar: ->
    @ui.statuses_tb_create.prop("disabled", true)
    @ui.statuses_tb_edit.prop("disabled", true)
    @ui.statuses_tb_delete.prop("disabled", true)
    @ui.statuses_tb_create_policy.prop("disabled", true)

  update_statuses_toolbar: ->
    selected = @statuses_table_.getSelectedModels()

    @block_statuses_toolbar()

    if helpers.can({type: 'status', action: 'edit'})
      @ui.statuses_tb_create.prop("disabled", false)

    if selected.length and helpers.can({type: 'policy_person', action: 'edit'})
      @ui.statuses_tb_create_policy.prop("disabled", false)

    return if _.find selected, (status) -> return status.get('EDITABLE') is 0

    if selected.length is 1 and helpers.can({type: 'status', action: 'edit'})
      @ui.statuses_tb_edit.prop("disabled", false)

    if selected.length and helpers.can({type: 'status', action: 'delete'})
      @ui.statuses_tb_delete.prop("disabled", false)

  select: (model) ->
    @statuses_table_.setSelectedRows [model]

  getSelectedModels: ->
    return @statuses_table_.getSelectedModels()

  clearSelection: ->
    @statuses_table_.clearSelection()

  onShow: ->
    # ToDo: Переделать на посылку сообщения о закрытии сайдбара
    $(App.Layouts.Application.sidebar.el).closest('.sidebar').hide()

    # Рендерим контролы
    @statuses_table.show @statuses_table_
    @statuses_paginator.show @statuses_paginator_

    @listenTo @collection, "change", @update_statuses_toolbar
    @listenTo @statuses_table_, "table:select", @update_statuses_toolbar
    @listenTo @statuses_table_, "table:sort", (args) => @trigger 'sort', args

    @listenTo @statuses_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @statuses_table_.grid.editActiveCell(@statuses_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @statuses_table_.grid.getActiveCellNode()

          if $(activeCellNode).data("bs.popover")
            $(activeCellNode).popover('destroy')

          $(activeCellNode).popover
            content: err
            placement: 'bottom'

          $(activeCellNode).popover('show')

    @statuses_table_.resize App.Layouts.Application.content.$el.height() - 160

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @statuses_table_.resize(args.height - 160)

    @update_statuses_toolbar()
