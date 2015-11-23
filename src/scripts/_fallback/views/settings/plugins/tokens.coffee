"use strict"

require "views/controls/table_view.coffee"
ZeroClipboard = require "zeroclipboard"
helpers = require "common/helpers.coffee"

module.exports = class TokensView extends App.Views.Controls.TableView

  # ***********
  #  TABLE
  # ***********
  _get_config = ->
    config :
      columns : [
        id            : "STATUS"
        resizable     : true
        field         : "STATUS"
        sortable      : true
        name          : App.t "settings.plugins.status"
        showIcons     : false
        editor        : Slick.BackboneEditors.Select
        editorValues  : [
          key: 1
          title: App.t "global.inactive"
        ,
          key: 0
          title: App.t "global.active"
        ]
        formatter     : (some..., model) ->
          if model.get("STATUS") is 0
            App.t "global.active"
          else
            App.t "global.inactive"
      ,
        editor    : Slick.BackboneEditors.Text
        id        : "DISPLAY_NAME"
        field     : "DISPLAY_NAME"
        resizable : true
        sortable  : true
        name      : App.t "settings.plugins.name"
      ,
        id        : "USERNAME"
        field     : "USERNAME"
        resizable : true
        sortable  : true
        name      : App.t "settings.plugins.content"
      ,
        id        : "NOTE"
        field     : "NOTE"
        resizable : true
        sortable  : true
        editor    : Slick.BackboneEditors.Text
        name      : App.t "settings.plugins.note"
      ]

  _onEdit: (item, column, editCommand) =>
    @trigger 'edit:inline', item, column.field, editCommand.serializedValue, (err) =>
      if (err)
        # Переводим ячейку в режим редактирования
        @grid.editActiveCell(@grid.getCellEditor())

        # Показываем ошибку
        activeCellNode = @grid.getActiveCellNode()

        if $(activeCellNode).data("bs.popover")
          $(activeCellNode).popover('destroy')

        $(activeCellNode).popover
          content: err
          placement: 'bottom'

        $(activeCellNode).popover('show')

  # **********
  #  INIT
  # **********
  initialize : ->
    super _get_config.call @
    @on "inline_edit", @_onEdit

    @_initZeroClipboard = false

  # **************
  #  BACKBONE
  # **************

  ui:
    createToken           : "[data-action='create_token']"
    copyTokenToClipboard  : "[data-action='copy_token']"
    regenerateToken       : "[data-action='regenerate_token']"
    removeToken           : "[data-action='remove_token']"

  triggers :
    "click [data-action='create_token']"      : "create_token"
    "click [data-action='remove_token']"      : "remove_tokens"
    "click [data-action='regenerate_token']"  : "regenerate_token"

  # ****************
  #  MARIONETTE
  # ****************

  template : "settings/plugins/tokens"


  _blockToolbar: ->
    @ui.createToken.prop 'disabled', true
    @ui.copyTokenToClipboard.prop 'disabled', true
    @ui.regenerateToken.prop 'disabled', true
    @ui.removeToken.prop 'disabled', true

  _updateToolbar: (selected) ->
    @_blockToolbar()

    if helpers.can({type: 'plugins', action: 'edit'})
      @ui.createToken.prop 'disabled', false

    if selected and selected.length and helpers.can({type: 'plugins', action: 'edit'})
      @ui.regenerateToken.prop 'disabled', false
      @ui.removeToken.prop 'disabled', false

      if @_initZeroClipboard and selected.length is 1
        @ui.copyTokenToClipboard.prop 'disabled', false

  # ***********************
  #  MARIONETTE-EVENTS
  # ***********************
  onShow : ->
    super

    clipboardClient = new ZeroClipboard(@ui.copyTokenToClipboard)

    clipboardClient.on 'ready', (event) =>

      @_initZeroClipboard = true

      clipboardClient.on 'copy', (event) =>
        selected = @getSelectedModels()

        event.clipboardData.setData('text/plain', selected[0].get 'USERNAME')

      clipboardClient.on 'aftercopy', (event) ->
        App.Notifier.showInfo
          title: App.t 'settings.plugins.tokens'
          text: App.t 'settings.plugins.token_copied'
          hide: true

    clipboardClient.on 'error', (event) ->
      ZeroClipboard.destroy()


    @listenTo @, "table:select", @_updateToolbar

    @resize App.Layouts.Application.content.$el.height() - 160,
      App.Layouts.Application.content.$el.width() - 10

    @_updateToolbar()
