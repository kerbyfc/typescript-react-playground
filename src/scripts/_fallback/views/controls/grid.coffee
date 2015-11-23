"use strict"

require "behaviors/common/search.coffee"
require "behaviors/common/paginator.coffee"
require "behaviors/common/drag.coffee"

require "common/entry.coffee"
entry   = require "common/entry.coffee"
style   = require "common/style.coffee"
helpers = require "common/helpers.coffee"

require "views/controls/table_view.coffee"

App.Views.Controls ?= {}

class App.Views.Controls.Grid extends App.Views.Controls.TableView

  reset: false

  template: "controls/grid/popup"

  $container: "[data-grid]"

  collectionEvents:
    reset: ->
      # TODO: checkbox не должен быть в default
      if @config.default?.checkbox
        @reset = true
      else
        @selected.reset()

      @stopListening @section, 'change' if @section

    request: (item) ->
      # если модель в режиме редактирования подсвечиваем ее
      if item.cid and item is @inlineItem?.model
        if activeCellNode = @grid.getActiveCellNode()

          $ activeCellNode
          .addClass "loading"

          return

      # если модель есть в гриде подсвечиваем поле названия модели
      if item.cid
        cell = @grid.getColumnIndex item.nameAttribute
        row  = @collection.indexOf item
        node = @grid.getCellNode row, cell
        $ node
        .addClass "loading"

        return

      @getContainer().attr 'data-state-loading', ''
      @getContainer().attr 'data-message', App.t "global.loading"

    error: (item) ->
      # если ошибка при инлайн редактировании -> показываем ошибку в поле редактирования
      if item.cid and item is @inlineItem?.model
        err = arguments[1].responseJSON
        models = err.model
        delete err.model
        err = item.error? err, models

        $ @inlineItem.activeCellNode
        .removeClass "loading"

        if @grid.getActiveCellNode() is @inlineItem.activeCellNode
          editor = @grid.getCellEditor()
          @grid.editActiveCell editor unless editor

          if error = err[@inlineItem.field]
            error = error[0] or error
          else if err.misc
            error = err.form[0]
          message = App.t error, defaultValue: error

          item.attributes[@inlineItem.field] = @inlineItem.prevValue

          $ @inlineItem.activeCellNode
          .addClass "invalid"

          $ 'input', @inlineItem.activeCellNode
          .val @inlineItem.value
          .attr 'data-content', message
          .focus()

        return

      @getContainer().removeAttr 'data-state-loading'
      unless @collection.getTotalLength()
        @getContainer().attr 'data-state-error', ''
        @getContainer().attr 'data-message', App.t("global.error_load")

    sync: (item, data) ->
      # снимаем лоадинг с той модели, которая пришла в ответе
      if item.cid and item is @inlineItem?.model
        activeCellNode = @grid.getActiveCellNode()

        $ activeCellNode
        .removeClass "loading"

    "add remove reset change sync": -> @update arguments...

  update: ->
    @collection.trigger "update", arguments...

    count = @collection.getTotalLength()
    c = @getContainer()

    c.removeAttr 'data-message'
    c.removeAttr 'data-state-loading'

    if count
      c.removeAttr 'data-empty'
      c.attr 'data-count', count
    else
      c.removeAttr 'data-count'
      c.attr 'data-empty', ''
      search = if @collection.searchQuery then '_search' else ''
      @getContainer().attr 'data-message', App.t("global.empty#{search}")

    if @config.default?.checkbox and not @reset
      selected = []
      @collection.each (model, i) =>
        selected.push i if @selected.get model.id

      @grid.setSelectedRows selected if @grid

    App.trigger "resize", "grid", @

  onCellCanEdit: (args) ->
    b = true
    return false if args.item.islock 'edit'
    b = args.item.onCellCanEdit args.column.field if args.item.onCellCanEdit
    b

  getContainer: -> $ @$container, @$el

  behaviors: ->
    Search    : {}
    Paginator : {}

  collectionChanged: ->
    restore = @grid.getSelectedRows()
    @clearSelection()
    @grid.setSelectedRows restore
    @grid.invalidate()

  resize: ->
    return unless @grid

    if @resizeElement
      $container = @getContainer().closest(@resizeElement)
    else
      $container = @getContainer().parent()

    w = $container.width()
    h = $container.height()

    $container.data 'width', w
    $container.data 'height', h

    options = @grid.getOptions()
    rowHeight = options.rowHeight
    headerRowHeight = options.headerRowHeight
    d = headerRowHeight + @collection.length * rowHeight

    # TODO: 15 в дальнейшем реализовать стилями
    height = if d < h then d + 15 else h
    height = d + 15 if @static

    super height, w

  initialize: (o) ->
    {@checkbox, @static} = o

    o.config = @config = _.result @collection, 'config'

    (@config.default ?= {}).checkbox = true if @checkbox

    proto = @collection.model::
    data = _.map @options.data, (model) -> model.content or model

    @selected = new Backbone.Collection data,
      model: Backbone.Model.extend
        idAttribute   : proto.idAttribute
        nameAttribute : proto.nameAttribute

    @type = proto.type or App.entry.getConfig(proto)?.type

    super

    @collection.getSelectedModels = => _.compact @getSelectedModels()

    # если не задано максимальное количество отображаемых элементов, устанавливаем 10
    if _.isUndefined @config.maxViewItems
      @config.maxViewItems = 10

    layouts = App.Layouts.Application

    Marionette.bindEntityEvents @, @collection, @collectionEvents

    @listenTo App, 'resize', @resize

    if @config.default?.checkbox
      @listenTo @, "table:select", (args) =>
        return @reset = false if @reset

        @selected.remove @collection.toArray() if @selected.length

        _.each args, (model) =>
          @selected.add model.toJSON()

        @trigger "change:data", @

    if _.isUndefined(isSortable = @config.sortable) or isSortable isnt false
      @listenTo @, "table:sort", _.bind(@collection.sortCollection, @collection)

    @listenTo @, "inline_edit", (item, column, editCommand) =>
      field = column.field
      value = editCommand.serializedValue

      @inlineItem =
        activeCellNode : @grid.getActiveCellNode()
        field     : field
        value     : value
        model     : item
        prevValue : item.get field

      item.inlineSave field, value, wait: true

    _.defer => @update() if @collection.length

  get: ->
    @selected.map (model) =>
      ID      : model.id
      NAME    : model.getName()
      TYPE    : @type
      content : model.toJSON()

class App.Views.Controls.ContentGrid extends App.Views.Controls.Grid

  getTemplate: ->
    tpl = if @options.popup or @popup then 'popup' else 'content'
    "controls/grid/#{tpl}"

  templateHelpers: ->
    type    : @type
    buttons : @buttons

  className: ->
    if @options.popup or @popup then 'popup__contentWrap' else 'content'

  behaviors: ->
    behaviors = super
    collection = @options.collection
    proto = collection.model::
    @type = proto.type
    @buttons = _.result collection, 'buttons'
    o = container: "#{@ui().toolbar}[data-type=#{@type}]"

    behaviors.Toolbar = _.extend o, _.result(@options.collection, 'toolbar')

    if @options.collection.model::can 'move'
      behaviors.Drag = behaviorClass: App.Behaviors.Grid.Drag
    behaviors

  ui: ->
    toolbar : "[data-ui=toolbar]"
    header  : "[data-ui=header]"

  select: (model) -> @grid.setSelectedRows [model]

  onShow: ->
    super
    categories = @options.categories
    @listenTo @collection, 'reset', @updateHeader
    @listenTo categories, "change", (model) =>
      section = @collection.section
      @updateHeader() if section is model

    @updateHeader()

  updateHeader: ->
    section = @collection.section

    text = if section and section.isRoot and not section.isRoot() then section.getName() else ''
    @ui.header.text text

    App.trigger "resize", "header", @
