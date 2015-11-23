"use strict"

helpers = require "common/helpers.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"

RoleDialog = require "views/settings/users_and_roles/role.coffee"

module.exports = class App.Views.Settings.Roles extends Marionette.LayoutView

  _initialize_controls = (self) ->
    self.roles_paginator_ = new App.Views.Controls.Paginator
      collection: self.collection

    self.roles_table_ = new App.Views.Controls.TableView
      collection: self.collection
      config:
        name: "rolesTable"
        default:
          sortCol: "DISPLAY_NAME"
        columns: [
          {
            id      : "DISPLAY_NAME"
            name    : App.t 'settings.roles.display_name_column'
            field   : "DISPLAY_NAME"
            resizable : true
            sortable  : true
            minWidth  : 100
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "users"
            name    : App.t 'settings.roles.users_column'
            resizable : true
            sortable  : true
            minWidth  : 120
            field   : "users"
            formatter : (row, cell, value, columnDef, dataContext) ->
              _.map dataContext.get(columnDef.field), (user) ->
                _.escape user.USERNAME
              .join(', ')
          }
          {
            id      : "NOTE"
            name    : App.t 'settings.roles.note_column'
            resizable : true
            sortable  : true
            minWidth  : 180
            field   : "NOTE"
            editor    : Slick.BackboneEditors.Text
          }
        ]

    self.roles_table_.onCellCanEdit = (args) ->
      if helpers.islock({type: 'role', action: 'edit'}) or
         parseInt(args.item.get 'EDITABLE', 10) is 0
        return false

      return true

  template: "settings/roles"

  className: 'content'

  regions:
    roles_table    : "#roles_table"
    roles_paginator  : "#roles_paginator"

  ui:
    roles_tb_create    : "[data-action='create_role']"
    roles_tb_show_edit   : "[data-action='edit_role']"
    roles_tb_delete    : "[data-action='delete_role']"

  events:
    "click .toolbar__actions button"     : "toolbar_action"

  block_roles_toolbar: ->
    @ui.roles_tb_create.prop("disabled", true)
    @ui.roles_tb_show_edit.prop("disabled", true)
    @ui.roles_tb_delete.prop("disabled", true)

  update_roles_toolbar: ->
    selected_roles = @roles_table_.getSelectedModels()

    @block_roles_toolbar()

    if helpers.can({type: 'role', action: 'edit'})
      @ui.roles_tb_create.prop("disabled", false)

    if selected_roles.length

      # Find roles with EDITABLE attribute
      if @_findEditableRoles(selected_roles) and helpers.can({type: 'role', action: 'edit'})
        if selected_roles.length is 1
          @ui.roles_tb_show_edit.prop("disabled", false)
          @_switchToEdit()

        if helpers.can({type: 'role', action: 'delete'})
          @ui.roles_tb_delete.prop("disabled", false)

      else if selected_roles.length is 1
        @ui.roles_tb_show_edit.prop("disabled", false)
        @_switchToShow()


  delete_role: ->
    selected = @roles_table_.getSelectedModels()

    if helpers.islock({type: 'role', action: 'delete'}) then return

    App.Helpers.confirm
      title: App.t 'settings.roles.role_delete_dialog_title'
      data: App.t 'settings.roles.role_delete_dialog_question',
        roles: App.t 'settings.roles.role', {count: selected.length}
      accept: =>
        $.each selected, (index, model) ->
          model.destroy
            data: JSON.stringify(model.toJSON())

        @roles_table_.clearSelection()
        @update_roles_toolbar()

  create_role: ->
    model = new @collection.model()

    if helpers.islock({type: 'role', action: 'edit'}) then return

    App.modal.show new RoleDialog
      title: App.t 'settings.roles.role_create_dialog_title'
      collection: @collection
      model: model
      callback: =>
        @roles_table_.setSelectedRows [model]


  toolbar_action: (e) ->
    e.preventDefault()

    if $(e.currentTarget).prop("disabled")
      return
    else
      @[$(e.currentTarget).data("action")]()

  show_role: ->
    selected = @roles_table_.getSelectedModels()

    if selected.length is 1
      App.modal.show new RoleDialog
        title: App.t 'settings.roles.role_show_dialog_title'
        collection: @collection
        model: selected[0]
        blocked: true

  edit_role: ->
    selected = @roles_table_.getSelectedModels()

    if selected.length is 1
      App.modal.show new RoleDialog
        title: App.t 'settings.roles.role_edit_dialog_title'
        collection: @collection
        model: selected[0]
        blocked: not helpers.can({type: 'role', action: 'edit'})

  onRolesSort: (args) ->
    if args.field is 'users'
      args.field = "#{args.field}.DISPLAY_NAME"

    data = {}
    data[args.field] = args.direction
    @collection.sortRule = data

    @collection.fetch
      reset: true

  onShow: ->
    _initialize_controls @

    # Рендерим контролы
    @roles_table.show @roles_table_
    @roles_paginator.show @roles_paginator_

    @listenTo @collection, "change", @update_roles_toolbar()
    @listenTo @roles_table_, "table:select", @update_roles_toolbar
    @listenTo @roles_table_, "table:sort", @onRolesSort

    @listenTo @roles_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @roles_table_.grid.editActiveCell(@scopes_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @roles_table_.grid.getActiveCellNode()

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

    @roles_table_.resize App.Layouts.Application.content.$el.height() - 100

    @update_roles_toolbar()

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @roles_table_.resize(args.height - 100)

  # Private

  _findEditableRoles: (selected_roles) ->
    -1 is _.findIndex selected_roles, (elem) ->
      parseInt(elem.get('EDITABLE'), 10) is 0

  _switchToEdit: ->
    @ui.roles_tb_show_edit
      .removeClass('_show')
      .addClass('_edit')
      .attr 'title', App.t 'settings.roles.edit'
      .data 'action', 'edit_role'

  _switchToShow: ->
    @ui.roles_tb_show_edit
      .removeClass('_edit')
      .addClass('_show')
      .attr 'title', App.t 'settings.roles.show'
      .data 'action', 'show_role'
