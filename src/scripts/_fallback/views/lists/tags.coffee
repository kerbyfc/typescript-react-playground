"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"

module.exports = class TagsView extends Marionette.LayoutView

  template: "lists/tags"

  className: 'content'

  regions:
    tags_table     : "#tags_table"
    tags_paginator   : "#tags_paginator"

  ui:
    tags_tb_create   : ".toolbar [data-action='create_tag']"
    tags_tb_edit   : ".toolbar [data-action='edit_tag']"
    tags_tb_delete   : ".toolbar [data-action='delete_tag']"

  triggers:
    "click .toolbar [data-action='create_tag']" : "create"
    "click .toolbar [data-action='edit_tag']" : "edit"
    "click .toolbar [data-action='delete_tag']" : "delete"

  initialize: ->
    @tags_paginator_ = new App.Views.Controls.Paginator
      collection: @collection
      showPageSize: true

    @tags_table_ = new App.Views.Controls.TableView
      collection: @collection
      config:
        name: 'tagsTable'
        default:
          sortCol: "DISPLAY_NAME"
        columns: [
          {
            id      : "COLOR"
            name    : ""
            menuName  : App.t 'lists.tags.color'
            field   : "COLOR"
            width   : 40
            resizable : false
            sortable  : true
            cssClass  : "center"
            formatter : (row, cell, value, columnDef, dataContext) ->
              "<div class='tag__color' data-color='#{dataContext.get(columnDef.field)}'></div>"
          }
          {
            id      : "DISPLAY_NAME"
            name    : App.t 'lists.tags.display_name'
            field   : "DISPLAY_NAME"
            resizable : true
            sortable  : true
            minWidth  : 150
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "NOTE"
            name    : App.t 'lists.tags.note'
            resizable : true
            sortable  : true
            minWidth  : 150
            field   : "NOTE"
            editor    : Slick.BackboneEditors.Text
          }
        ]

    @tags_table_.onCellCanEdit = (args) ->
      if args.item.get('IS_SYSTEM') is 1 or
         helpers.islock({type: 'tag', action: 'edit'})
        return false

      return true

  block_tags_toolbar: ->
    @ui.tags_tb_create.prop("disabled", true)
    @ui.tags_tb_edit.prop("disabled", true)
    @ui.tags_tb_delete.prop("disabled", true)

  update_tags_toolbar: ->
    selected = @tags_table_.getSelectedModels()

    @block_tags_toolbar()

    if helpers.can({type: 'tag', action: 'edit'})
      @ui.tags_tb_create.prop("disabled", false)

    return if _.find selected, (tag) -> return tag.get('IS_SYSTEM') is 1

    if selected.length is 1 and helpers.can({type: 'tag', action: 'edit'})
      @ui.tags_tb_edit.prop("disabled", false)

    if selected.length and helpers.can({type: 'tag', action: 'delete'})
      @ui.tags_tb_delete.prop("disabled", false)

  select: (model) ->
    @tags_table_.setSelectedRows [model]

  getSelectedModels: ->
    return @tags_table_.getSelectedModels()

  clearSelection: ->
    @tags_table_.clearSelection()

  onShow: ->
    # ToDo: Переделать на посылку сообщения о закрытии сайдбара
    $(App.Layouts.Application.sidebar.el).closest('.sidebar').hide()

    # Рендерим контролы
    @tags_table.show @tags_table_

    @tags_paginator.show @tags_paginator_

    @listenTo @collection, "change", @update_tags_toolbar
    @listenTo @tags_table_, "table:select", @update_tags_toolbar
    @listenTo @tags_table_, "table:sort", (args) => @trigger 'sort', args

    @listenTo @tags_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @tags_table_.grid.editActiveCell(@tags_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @tags_table_.grid.getActiveCellNode()

          if $(activeCellNode).data("bs.popover")
            $(activeCellNode).popover('destroy')

          $(activeCellNode).popover
            content: err
            placement: 'bottom'

          $(activeCellNode).popover('show')

    @tags_table_.resize App.Layouts.Application.content.$el.height() - 160

    @update_tags_toolbar()

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @tags_table_.resize(args.height - 160)
