"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"

module.exports = class ResourceListItems extends Marionette.LayoutView

  template: "lists/resource_list_items"

  className: 'content'

  regions:
    resources_table         : "#resource_list_items"
    resources_paginator     : "#resources_paginator"
    resource_groups         : "#resource_groups"

  ui:
    search                      : '[data-action="search"]'
    resources_tb_create         : ".toolbar__actions [data-action=create_resource]"
    resources_tb_edit           : ".toolbar__actions [data-action=edit_resource]"
    resources_tb_delete         : ".toolbar__actions [data-action=delete_resource]"
    resources_tb_create_policy  : ".toolbar__actions [data-action=create_policy_resource]"

  triggers:
    "click .toolbar__actions [data-action=create_resource]"         : "create"
    "click .toolbar__actions [data-action=edit_resource]"           : "edit"
    "click .toolbar__actions [data-action=delete_resource]"         : "delete"
    "click .toolbar__actions [data-action=create_policy_resource]"  : "create_policy"

  collectionEvents:
    'change'  : 'update_resources_toolbar'

  templateHelpers: ->
    resourceGroup: @options.selected?.get('DISPLAY_NAME') or ''

  initialize: ->
    @resources_paginator_ = new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: true

    @resources_table_ = new App.Views.Controls.TableView
      collection: @collection
      config:
        name: 'resourcesTable'
        default:
          sortCol: "VALUE"
        formatter: (row, cell, value, col, data) ->
          _.unescape data.get(col.field)
        columns: [
          {
            id        : "VALUE"
            name      : App.t 'lists.resources.value'
            field     : "VALUE"
            resizable : true
            sortable  : true
            minWidth  : 150
            editor    : Slick.BackboneEditors.Text
          }
          {
            id        : "NOTE"
            name      : App.t 'lists.resources.note'
            resizable : true
            sortable  : true
            minWidth  : 150
            field     : "NOTE"
            editor    : Slick.BackboneEditors.Text
          }
        ]

    @resources_table_.onCellCanEdit = (args) ->
      if helpers.islock({type: 'resource', action: 'edit'})
        return false

      return true

  block_resources_toolbar: ->
    @ui.resources_tb_create.prop("disabled", true)
    @ui.resources_tb_edit.prop("disabled", true)
    @ui.resources_tb_delete.prop("disabled", true)

  update_resources_toolbar: ->
    selected = @resources_table_.getSelectedModels()

    @block_resources_toolbar()

    if helpers.can({type: 'resource', action: 'edit'})
      @ui.resources_tb_create.prop("disabled", false)

    if selected.length is 1 and helpers.can({type: 'resource', action: 'edit'})
      @ui.resources_tb_edit.prop("disabled", false)

    if selected.length and helpers.can({type: 'resource', action: 'delete'})
      @ui.resources_tb_delete.prop("disabled", false)

  select: (model) ->
    @resources_table_.setSelectedRows [model]

  getSelectedModels: ->
    return @resources_table_.getSelectedModels()

  clearSearch: ->
    @ui.search.val('')

  clearSelection: ->
    @resources_table_.clearSelection()

  onShow: ->
    throttled = =>
      val = @ui.search.val()

      @collection.filterResources val

    @ui.search.keyup _.throttle throttled, 1000, 'leading': false

    # Рендерим контролы
    @resources_table.show @resources_table_

    @resources_paginator.show @resources_paginator_

    @listenTo @resources_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @resources_table_.grid.editActiveCell(@resources_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @resources_table_.grid.getActiveCellNode()

          if $(activeCellNode).data("bs.popover")
            $(activeCellNode).popover('destroy')

          $(activeCellNode).popover
            content: err
            placement: 'bottom'

          $(activeCellNode).popover('show')

    @listenTo @resources_table_, "table:select", @update_resources_toolbar
    @listenTo @resources_table_, "table:sort", _.bind(@collection.sortCollection, @collection)

    @update_resources_toolbar()

    @listenTo @resources_table_, "table:enter_edit_mode", =>
      @block_resources_toolbar()

    @listenTo @resources_table_, "table:leave_edit_mode", =>
      @update_resources_toolbar()

    @listenTo App.Layouts.Application.sidebar, 'sidebar:hide sidebar:show', =>
      @resources_table_.onResize()

    @resources_table_.resize App.Layouts.Application.content.$el.height() - 160

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @resources_table_.resize(args.height - 160)
