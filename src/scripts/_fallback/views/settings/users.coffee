"use strict"

helpers = require "common/helpers.coffee"
ImportUserDialog = require "views/settings/dialogs/import_user.coffee"
require "layouts/dialogs/confirm.coffee"
require "views/controls/table_view.coffee"
require "views/controls/paginator.coffee"
require "views/settings/users_and_roles/user.coffee"

Roles = require "models/settings/role.coffee"
Scopes = require "models/settings/scope.coffee"
ChangePasswordDialog = require "views/settings/users_and_roles/change_password.coffee"

module.exports = class App.Views.Settings.Users extends Marionette.LayoutView

  _initialize_controls = (self) ->
    self.users_paginator_ = new App.Views.Controls.Paginator
      collection: self.collection

    self.users_table_ = new App.Views.Controls.TableView
      collection: self.collection
      config:
        name: "usersTable"
        default:
          sortCol: "USERNAME"
        columns: [
          {
            id      : "STATUS"
            name    : ""
            menuName  : App.t 'settings.roles.status'
            field   : "STATUS"
            width   : 40
            resizable : false
            sortable  : true
            cssClass  : "center"
            formatter : (row, cell, value, columnDef, dataContext) ->
              if parseInt(dataContext.get(columnDef.field), 10) is 0
                "<span class='protected__itemIcon _active'></span>"
              else
                "<span class='protected__itemIcon _inactive'></span>"
          }
          {
            id      : "USERNAME"
            name    : App.t 'settings.users.username_column'
            field   : "USERNAME"
            resizable : true
            sortable  : true
            minWidth  : 130
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "DISPLAY_NAME"
            name    : App.t 'settings.users.fullname_column'
            resizable : true
            sortable  : true
            minWidth  : 170
            field   : "DISPLAY_NAME"
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "EMAIL"
            name    : App.t 'settings.users.email_column'
            resizable : true
            sortable  : true
            minWidth  : 130
            field   : "EMAIL"
            editor    : Slick.BackboneEditors.Text
          }
          {
            id      : "roles"
            name    : App.t 'settings.users.roles_column'
            resizable : true
            sortable  : true
            minWidth  : 150
            field   : "roles"
            formatter : (row, cell, value, columnDef, dataContext) ->
              _.map dataContext.get(columnDef.field).models, (role) ->
                _.escape role.get('DISPLAY_NAME')
              .join(', ')
          }
          {
            id      : "visibilityareas"
            name    : App.t 'settings.scopes_tab'
            resizable : true
            sortable  : true
            minWidth  : 140
            field   : "visibilityareas"
            formatter : (row, cell, value, columnDef, dataContext) ->
              _.map dataContext.get(columnDef.field).models, (scope) ->
                _.escape scope.get('DISPLAY_NAME')
              .join(', ')
          }
          {
            id      : "NOTE"
            name    : App.t 'settings.users.note_column'
            resizable : true
            sortable  : true
            minWidth  : 150
            field   : "NOTE"
            editor    : Slick.BackboneEditors.Text
            formatter : (row, cell, value, columnDef, dataContext) ->
              if dataContext.get(columnDef.field)
                _.escape dataContext.get(columnDef.field)
          }
        ]

    _alreadyImported = []

    self.users_table_.onCellCanEdit = (args) ->
      if helpers.islock({action: 'edit', type: 'user'}) or
         parseInt(args.item.get('EDITABLE'), 10) is 0
        return false

      return true

    _notifyUsersAlreadyImported = _.throttle(
      ->
        PNotify.removeAll()
        users = _(_alreadyImported).map((m) -> m.toJSON()).pluck('NAME').value()
        plural = (users.length > 1) and  '_plural' or ''
        App.Notifier.showError
          text: App.t "settings.users.already_imported#{plural}",
            users: users.join ', '
            count: users.length
          delay: 4000
      1000
      leading: false
    )

  className: 'content'

  regions:
    users_table             : "#users_table"
    users_paginator         : "#users_paginator"

  template: "settings/users"

  ui:
    users_tb_create         : "[data-action='create_user']"
    users_tb_edit           : "[data-action='edit_user']"
    users_tb_delete         : "[data-action='delete_user']"
    users_tb_activate       : "[data-action='activate_user']"
    users_tb_deactivate     : "[data-action='deactivate_user']"
    users_change_password   : "[data-action='change_password']"
    users_tb_set_role       : "[data-action='set_role']"
    users_tb_set_scope      : "[data-action='set_scope']"
    users_tb_import_ad      : "[data-action='import_ad']"

  events:
    "click .toolbar__actions button" : "toolbar_action"

  block_users_toolbar: ->
    @ui.users_tb_create.prop("disabled", true)
    @ui.users_tb_edit.prop("disabled", true)
    @ui.users_tb_delete.prop("disabled", true)
    @ui.users_tb_activate.prop("disabled", true)
    @ui.users_tb_deactivate.prop("disabled", true)
    @ui.users_tb_set_role.prop("disabled", true)
    @ui.users_change_password.prop("disabled", true)
    @ui.users_tb_set_scope.prop("disabled", true)
    @ui.users_tb_import_ad.prop("disabled", true)

  update_users_toolbar: ->
    selected = @users_table_.getSelectedModels()

    @block_users_toolbar()

    # ## Разрешаем создание пользователей
    if helpers.can({action: 'edit', type: 'user'})
      @ui.users_tb_create.prop("disabled", false)
      @ui.users_tb_import_ad.prop("disabled", false)

    #return if _.find selected, (user) -> return parseInt(user.get('EDITABLE'), 10) is 0

    if selected.length is 1
      if  selected[0].get('PROVIDER') isnt 'LDAP' and
          helpers.can({action: 'edit', type: 'user'})
        @ui.users_change_password.prop("disabled", false)

    if selected.length and _.every(selected, (elem) -> elem.isEditable())
      if selected.length is 1 and helpers.can({type: 'user', action: 'edit'})
        @ui.users_tb_edit.prop("disabled", false)

      if  helpers.can({action: 'delete', type: 'user'}) and
          not (_.some selected, (elem) -> elem.isPredefined())
        @ui.users_tb_delete.prop("disabled", false)

      if helpers.can({action: 'set_role', type: 'user'})
        @ui.users_tb_set_role.prop("disabled", false)

      if helpers.can({action: 'set_scope', type: 'user'})
        @ui.users_tb_set_scope.prop("disabled", false)

      if helpers.can({action: 'edit', type: 'user'})
        if selected.length is 1
          if selected[0].isActive()
            @ui.users_tb_activate.prop("disabled", false)
          else
            @ui.users_tb_deactivate.prop("disabled", false)
        else
          if _.some(selected, (elem) -> elem.isActive())
            @ui.users_tb_activate.prop("disabled", false)
          unless _.every(selected, (elem) -> elem.isActive())
            @ui.users_tb_deactivate.prop("disabled", false)

  change_password: ->
    return if helpers.islock({status: 'edit', type: 'user'})

    selected = @users_table_.getSelectedModels()

    App.modal.show new ChangePasswordDialog
      title: App.t 'settings.users.change_password_title'
      model: selected[0]

  delete_user: ->
    return if helpers.islock({status: 'delete', type: 'user'})

    selected = @users_table_.getSelectedModels()

    has_current_user = _.find selected, (user) ->
      parseInt(user.get('USER_ID'), 10) is parseInt(App.Session.currentUser().get('USER_ID'), 10)

    if has_current_user
      attention = App.t 'settings.users.delete_user_attention'
    else
      attention = ''


    App.Helpers.confirm
      title: App.t 'settings.users.user_delete_dialog_title'
      data: App.t 'settings.users.user_delete_dialog_question',
        users: App.t 'settings.users.user', {count: selected.length}
        attention: attention
      accept: =>
        $.each selected, (index, model) ->
          model.destroy
            wait: true
            data: JSON.stringify(model.toJSON())


        @users_table_.clearSelection()
        @update_users_toolbar()

        App.vent.trigger("auth:logout") if has_current_user

  set_scope: ->
    return if helpers.islock({status: 'set_scope', type: 'user'})

    selected = @users_table_.getSelectedModels()

    scopes_ = []

    _.each selected, (user) ->
      for scope in user.get('visibilityareas').models
        scopes_.push
          TYPE: 'scope'
          ID: scope.id
          content: scope

    App.modal.show new App.Views.Controls.DialogSelect
      action                  : "add"
      type                    : "scope"
      checkbox                : false
      data                    : scopes_
      items                   : ['scope']
      preventSubmitDisabling  : true
      callback: (data) ->
        scopes = _.map data[0], (item) ->
          new Scopes.Model item.content

        $.each selected, (index, model) ->
          model.save
            visibilityareas: scopes
          ,
            wait: true

        App.modal.empty()

  set_role: ->
    return if helpers.islock({status: 'set_role', type: 'user'})

    selected = @users_table_.getSelectedModels()

    roles_ = []

    _.each selected, (user) ->
      for role in user.get('roles').models
        roles_.push
          TYPE  : 'role'
          ID    : role.id
          content : role

    App.modal.show new App.Views.Controls.DialogSelect
      action                  : "add"
      type                    : "role"
      checkbox                : false
      data                    : roles_
      items                   : ['role']
      preventSubmitDisabling  : true
      callback: (data) ->
        roles = _.map data[0], (item) ->
          new Roles.Model item.content

        $.each selected, (index, model) ->
          model.save
            roles: roles
          ,
            wait: true

        App.modal.empty()

  activate_user: ->
    return if helpers.islock({status: 'edit', type: 'user'})

    selected = @users_table_.getSelectedModels()

    $.each selected, (index, model) ->
      model.save "STATUS": "0",
        wait: true
        forceUpdate: true

  deactivate_user: ->
    return if helpers.islock({status: 'edit', type: 'user'})

    selected = @users_table_.getSelectedModels()

    $.each selected, (index, model) ->
      model.save "STATUS": 1,
        wait: true
        forceUpdate: true

  toolbar_action: (e) ->
    e.preventDefault()

    if $(e.currentTarget).prop("disabled")
      return
    else
      @[$(e.currentTarget).data("action")]()

  edit_user: ->
    selected = @users_table_.getSelectedModels()

    if selected.length is 1
      App.modal.show new App.Views.Settings.UserDialog
        title: App.t 'settings.users.user_edit_dialog_title'
        collection: @collection
        model: selected[0]
        blocked: not helpers.can({status: 'edit', type: 'user'})

  create_user: ->
    return if helpers.islock({status: 'edit', type: 'user'})

    model = new @collection.model()

    App.modal.show new App.Views.Settings.UserDialog
      title: App.t 'settings.users.user_create_dialog_title'
      collection: @collection
      model: model
      callback: =>
        @users_table_.setSelectedRows [model]

  import_ad: ->
    return if helpers.islock({status: 'edit', type: 'user'})

    App.modal.show new ImportUserDialog
      title: App.t 'settings.users.choose_ad_users_for_import'
      imported: @collection
      callback: (data, server) =>
        _alreadyImported = []
        _.each data, (user) =>
          user.fetch(
            url: """
              #{user.url_user_info}
              #{user.id}
              &server_id=#{server}
            """
            success: (model) =>
              @collection.create(
                _.extend(
                  _.omit(model.toJSON(), 'USER_ID')
                  PROVIDER: "LDAP"
                  LDAP_SERVER_ID: server
                )
                validate: false
                wait: true
                error: (req, res) =>
                  _data = res.responseJSON
                  if 'USERNAME' of _data
                    switch _data.USERNAME.toString()
                      when "not_unique_field"
                        @notifyUserAlreadyImported model

              )
          )

  notifyUserAlreadyImported: (model) ->
    _alreadyImported.push model
    _notifyUsersAlreadyImported()

  onUsersSort: (args) ->
    if args.field in ['roles', 'visibilityareas']
      args.field = "#{args.field}.DISPLAY_NAME"

    # Формируем параметры запроса
    data = {}
    data.sort = {}
    data.sort[args.field] = args.direction

    @collection.sortRule = data

    @collection.fetch
      reset: true

  onShow: ->
    _initialize_controls @

    # Рендерим контролы
    @users_table.show @users_table_
    @users_paginator.show @users_paginator_

    @listenTo @collection, "change", @update_users_toolbar
    @listenTo @users_table_, "table:select", @update_users_toolbar
    @listenTo @users_table_, "table:sort", @onUsersSort

    @listenTo @users_table_, "inline_edit", (item, column, editCommand) =>
      @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
        if (err)
          # Переводим ячейку в режим редактирования
          @users_table_.grid.editActiveCell(@users_table_.grid.getCellEditor())

          # Показываем ошибку
          activeCellNode = @users_table_.grid.getActiveCellNode()

          if $(activeCellNode).data("bs.popover")
            $(activeCellNode).popover('destroy')

          $(activeCellNode).popover
            content: err
            placement: 'bottom'

          $(activeCellNode).popover('show')


    if not @collection.sortRule
      @collection.sortRule = sort:
        "USERNAME": "ASC"

    _.defer =>
      @collection.fetch
        reset: true

    @users_table_.resize App.Layouts.Application.content.$el.height() - 120

    @update_users_toolbar()

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @users_table_.resize(args.height - 120)
