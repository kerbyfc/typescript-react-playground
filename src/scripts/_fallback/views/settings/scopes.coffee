"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"

ScopeDialog = require "views/settings/users_and_roles/scope.coffee"

module.exports = class App.Views.Settings.Scopes extends Marionette.LayoutView

  _initialize_controls = (self) ->
    self.scopes_paginator_ = new App.Views.Controls.Paginator
      collection: self.collection

    self.scopes_table_ = new App.Views.Controls.TableView
      collection: self.collection
      config:
        name: "scopesTable"
        default:
          sortCol: "DISPLAY_NAME"
        columns: [
          {
            id      : "DISPLAY_NAME"
            name    : App.t 'settings.roles.display_name_column'
            field   : "DISPLAY_NAME"
            resizable : true
            sortable  : true
            minWidth  : 200
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "NOTE"
            name    : App.t 'settings.roles.note_column'
            resizable : true
            sortable  : true
            minWidth  : 50
            field   : "NOTE"
            editor    : Slick.BackboneEditors.Text
          }
        ]

    self.scopes_table_.onCellCanEdit = (args) ->
      if not helpers.can({ action: 'edit', type: 'scope' }) or
         parseInt(args.item.get 'IS_SYSTEM', 10)
        return false

      return true

  template: "settings/scopes"

  className: 'content'

  regions:
    scopes_table    : "#scopes_table"
    scopes_paginator  : "#scopes_paginator"

  ui:
    scopes_tb_create    : "[data-action='create_scope']"
    scopes_tb_edit      : "[data-action='edit_scope']"
    scopes_tb_delete    : "[data-action='delete_scope']"

  events:
    "click .toolbar__actions button"     : "toolbar_action"

  block_scopes_toolbar: ->
    @ui.scopes_tb_create.prop("disabled", true)
    @ui.scopes_tb_edit.prop("disabled", true)
    @ui.scopes_tb_delete.prop("disabled", true)

  update_scopes_toolbar: ->
    selected_scopes = @scopes_table_.getSelectedModels()

    @block_scopes_toolbar()

    if helpers.can({ action: 'edit', type: 'scope' })
      @ui.scopes_tb_create.prop("disabled", false)

    if selected_scopes.length
      if selected_scopes.length is 1
        @ui.scopes_tb_edit.prop("disabled", false)

      if selected_scopes.length and helpers.can({ action: 'delete', type: 'scope' }) and
      (_.findIndex selected_scopes, (elem) -> return parseInt(elem.get('IS_SYSTEM'), 10) is 1) is -1
        @ui.scopes_tb_delete.prop("disabled", false)

  delete_scope: ->
    selected = @scopes_table_.getSelectedModels()

    if not helpers.can({ action: 'delete', type: 'scope' }) then return

    App.Helpers.confirm
      title: App.t 'settings.scopes.scope_delete_dialog_title'
      data: App.t 'settings.scopes.scope_delete_dialog_question',
        scopes: App.t 'settings.scopes.scope', {count: selected.length}
      accept: =>
        $.each selected, (index, model) ->
          model.destroy
            data: JSON.stringify(model.toJSON())

        @scopes_table_.clearSelection()
        @update_scopes_toolbar()

  create_scope: ->
    model = new @collection.model()

    if not helpers.can({ action: 'edit', type: 'scope' }) then return

    App.modal.show new ScopeDialog
      title: App.t 'settings.scopes.scope_create_dialog_title'
      collection: @collection
      model: model
      callback: =>
        @scopes_table_.setSelectedRows [model]


  toolbar_action: (e) ->
    e.preventDefault()

    if $(e.currentTarget).prop("disabled")
      return
    else
      @[$(e.currentTarget).data("action")]()

  edit_scope: ->
    selected = @scopes_table_.getSelectedModels()

    if selected.length is 1
      App.modal.show new App.Views.Settings.ScopeDialog
        title: App.t 'settings.scopes.scope_edit_dialog_title'
        collection: @collection
        model: selected[0]
        blocked: not helpers.can({ action: 'edit', type: 'scope' })

  onScopesSort: (args) ->
    data = {}
    data[args.field] = args.direction
    @collection.sortRule = data

    @collection.fetch
      reset: true

  onShow: ->
    _initialize_controls @

    # Рендерим контролы
    @scopes_table.show @scopes_table_
    @scopes_paginator.show @scopes_paginator_

    @listenTo @collection, "change", @update_scopes_toolbar()
    @listenTo @scopes_table_, "table:select", @update_scopes_toolbar
    @listenTo @scopes_table_, "table:sort", @onScopesSort

    @listenTo @scopes_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @scopes_table_.grid.editActiveCell(@scopes_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @scopes_table_.grid.getActiveCellNode()

          if $(activeCellNode).data("bs.popover")
            $(activeCellNode).popover('destroy')

          $(activeCellNode).popover
            content: err
            placement: 'bottom'

          $(activeCellNode).popover('show')

    if not @collection.sortRule
      @collection.sortRule =
        "DISPLAY_NAME": "ASC"

    @collection.fetch
      reset: true

    @scopes_table_.resize App.Layouts.Application.content.$el.height() - 100

    @update_scopes_toolbar()

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @scopes_table_.resize(args.height - 100)
