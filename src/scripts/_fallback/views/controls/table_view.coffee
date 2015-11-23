"use strict"

require "jquery-ui"
require "node_modules/jquery.event.drag-drop/event.drag/jquery.event.drag.js"
require "node_modules/jquery.event.drag-drop/event.drop/jquery.event.drop.js"
require "node_modules/slickgrid/slick.core.js"
require "node_modules/slickgrid/slick.formatters.js"
require "node_modules/slickgrid/slick.editors.js"
require "node_modules/slickgrid/plugins/slick.autotooltips.js"
require "node_modules/slickgrid/plugins/slick.cellrangeselector.js"
require "node_modules/slickgrid/plugins/slick.cellrangedecorator.js"
require "node_modules/slickgrid/plugins/slick.cellselectionmodel.js"
require "node_modules/slickgrid/plugins/slick.rowselectionmodel.js"
require "node_modules/slickgrid/plugins/slick.rowmovemanager.js"
require "app/scripts/vendor/slickgrid/plugins/slick.checkboxselectcolumn.js"
require "app/scripts/vendor/slickgrid/plugins/slick.rowdragmanager.js"
require "app/scripts/vendor/slickgrid/slick.columnpicker.js"
require "node_modules/slickgrid/slick.dataview.js"
require "slickgrid"

App.Views.Controls ?= {}

class App.Views.Controls.TableView extends Marionette.LayoutView

  # *************
  #  PRIVATE
  # *************
  _animation_ids = {}

  $container: ".grid-container"

  template: "controls/table"

  initialize: (options) ->
    if options and options.config
      @config = options.config

      # when config.columns declared as object, which keys represent fields
      unless _.isArray @config.columns
        @config.columns = _.reduce @config.columns, (acc, obj, key) ->
          defaults = field: key, id: key
          acc.push _.merge defaults, obj
          acc
        , []

      @config.autosizeColumns ?= true

      if @config.default?.checkbox
        @checkboxSelector = new Slick.CheckboxSelectColumn
          cssClass: "slick-cell-checkboxsel"
          locale:
            menuName: App.t "global.select_element"
          toolTip: "
            #{ App.t "global.select" }/\
            #{ App.t "global.cancel" }
            #{ App.t "global.all" }
          "

        if (@config.columns[0].cssClass and @config.columns[0].cssClass is "slick-cell-checkboxsel")
          @config.columns.splice 0, 1, @checkboxSelector.getColumnDefinition()
        else
          @config.columns.splice 0, 0, @checkboxSelector.getColumnDefinition()

    @$container = options.$container if options.$container

    @disabled = if @config and @config.disabled then @config.disabled else false
    super options

  # get checkbox column plugin instance definition
  # and do some overrides
  #
  # @return [Object] column definition object
  #
  setupCheckboxColumnDefinition: ->

    if @checkboxSelector?

      definition = @checkboxSelector.getColumnDefinition()

      # overide checkbox column formatter
      originalFormatter = definition?.formatter

      # formatter for Slick.CheckboxSelectColumn
      #
      # @param row   [ Number ] row index
      # @param cell  [ Number ] cell index
      # @param value [ String ] cell content
      # @param col   [ Object ] column definition
      # @param model [ Model  ] backbone model
      #
      definition.formatter = (row, cell, value, col, model) ->

        # check if model marked as unselectable
        # for slickgrid plugin
        if (meta = model.getMetadata?()) and
          _.isObject(meta) and
            meta.selectable is false
          return null

        # else apply original formatter
        originalFormatter? arguments...

      definition

  destroy: ->
    @columnpicker.destroy() if @columnpicker
    super

  resizeHeadersOnLoad: ->
    @listenToOnce @collection, "reset", =>
      @grid.autosizeColumns() if @grid

  collectionReload: ->
    @grid.getEditorLock().cancelCurrentEdit()
    @clearSelection()
    @grid.resizeCanvas()
    @grid.invalidate()

  onResize: ->
    @grid.resizeCanvas()
    @grid.autosizeColumns()

  collectionChanged: ->
    @grid.invalidate()

  collectionAdd: ->
    cancel-animation-frame _animation_ids[@cid]
    _animation_ids[@cid] = requestAnimationFrame =>
      @grid.resizeCanvas()
      @grid.invalidate()

  disable: -> @disabled = true

  enable: -> @disabled = false

  commandHandler: (item, column, editCommand) =>
    @trigger 'inline_edit', item, column, editCommand

  # object with getFormatter method is required by slickgrid
  formatter: (row, cell, value, col, data) ->
    _.escape data.get(col.field)

  onShow: ->
    options =
      editable              : @config.default?.editable ? true
      enableCellNavigation  : true
      enableAsyncPostRender : true
      asyncEditorLoading    : false
      enableColumnReorder   : @config.default?.enableColumnReorder ? true
      forceFitColumns       : @config.forceFitColumns ? false
      fullWidthRows         : true
      syncColumnCellResize  : true
      autoHeight            : @config.default?.autoHeight or false
      autoEdit              : false
      rowHeight             : if @config.default and @config.default.rowHeight then @config.default.rowHeight else 30
      formatterFactory      : getFormatter: => @config.formatter or @formatter
      editCommandHandler    : @commandHandler

    if not (@config.loadColumns? and @config.loadColumns is false)
      columns = JSON.parse localStorage.getItem(@config.name) if @config.name

      if columns
        columns = _.filter @config.columns, (column) ->
          columns.indexOf(column.id) isnt -1

    if @$container instanceof Object
      @grid = new Slick.Grid @$container, @collection, columns ? @config.columns, options
    else
      @grid = new Slick.Grid @$el.find(@$container), @collection, columns ? @config.columns, options

    @grid.registerPlugin new Slick.AutoTooltips

    if @config.default?.checkbox
      @grid.registerPlugin @checkboxSelector

    if @config.default?.enableColumnPicker? is false or @config.default.enableColumnPicker
      @columnpicker = new Slick.Controls.ColumnPicker @config.columns, @grid, _.assign options,
        forceFitColumnsLabel: App.t "global.forceFitColumnsLabel"
        syncResizeLabel: App.t "global.syncResizeLabel"

    if @config.default?.sortCol
      # Выставляем дефолтную сортировку
      @grid.setSortColumn(
        @config.default.sortCol
        @config.default.sortAsc
      )

    if @config.default?.checkbox
      @grid.setSelectionModel new Slick.RowSelectionModel selectActiveRow: false
    else
      @grid.setSelectionModel new Slick.RowSelectionModel

    if @config.sortable
      @moveRowsPlugin = new Slick.RowMoveManager
        cancelEditOnDrag: true

      @grid.registerPlugin @moveRowsPlugin

    @grid.onSort.subscribe (e, args) =>
      # do noting right after column resize
      if @preventSorting?
        e.stopPropagation()
        return false

      @grid.getEditController().commitCurrentEdit()

      @triggerMethod "table:sort",
        field   : args.sortCol.field
        direction : if args.sortAsc then 'asc' else 'desc'

    # slickgrid handles both resize and sort handlers
    # separately (each handler processes its own event
    # and stopping event propagation doesn't affect for
    # the second handler e.g. `onSort`)
    # http://stackoverflow.com/a/16878931
    # Based on this you can see this hack
    #
    # @param e      [ Event  ]
    # @param args   [ Object ]
    # @option args grid [ Grid   ] slickgrid instance
    #
    @grid.onColumnsResized.subscribe (e, args) =>
      # mark grid as unsortable
      @preventSorting = true
      # save sorting state
      colstash = @grid.getSortColumns()
      # reset sorting
      @grid.setSortColumns []
      _.defer =>
        @preventSorting = null
        # restore sorging state
        @grid.setSortColumns colstash

    @grid.onBeforeEditCell.subscribe (e, args) =>
      if @disabled or
          @onCellCanEdit and not @onCellCanEdit args
        false
      else
        @trigger "table:enter_edit_mode", args
        true

    @grid.onClick.subscribe (e, args) =>
      if "slick-viewport" in e.currentTarget.classList
        if @blocked
          e.stopImmediatePropagation()
        else
          @triggerMethod "table:click",
            args.grid.getDataItem args.row
            e
            args

    @grid.onDblClick.subscribe (e, args) =>
      e.stopImmediatePropagation() if @blocked

    @grid.onBeforeCellEditorDestroy.subscribe (e, args) ->
      if element = args.editor.getEl?()
        element.closest('.slick-cell').popover("destroy")

    @grid.onSelectedRowsChanged.subscribe (e, args) =>
      selected = _.map args.rows, (id) =>
        @collection.at(id)

      selected.splice(0, 1) if selected[0] is undefined

#          if selected.length > 1
#            @grid.resetActiveCell()

      @trigger(
        "table:select"
        if selected.length  then selected  else null
        e
        args
      )

    @grid.onHeaderCellRendered.subscribe _.throttle =>
      columns = _.pluck @grid.getColumns(), 'id'
      localStorage.setItem @config.name, JSON.stringify columns if @config.name
    , 300,
      'trailing': false

    @grid.onColumnsReordered.subscribe =>
      @trigger "table:column_reorder"

    @grid.onBeforeCellEditorDestroy.subscribe (e, args) =>
      $ args.grid.getActiveCellNode()
      .removeClass "invalid"
      .find 'input'
      .popover "destroy"

      @trigger "table:leave_edit_mode", args

    @grid.onValidationError.subscribe (e, args) ->
      validationResult = args.validationResults
      activeCellNode = args.cellNode
      errorMessage = validationResult.msg

      $ activeCellNode
      .find 'input'
      .attr "data-content", errorMessage

    @listenTo @collection, "add", @collectionAdd, @
    @listenTo @collection, "remove change sort", @collectionChanged, @
    @listenTo @collection, "add remove reset", =>
      @trigger "table:count", @getLength()

    # Для перезагрузки коллекции вызываем колбек с очисткой выделения
    @listenTo @collection, "reset", @collectionReload, @

    @resizeHeadersOnLoad() if @config.autosizeColumns

    @.$el.find('.grid-canvas').on "click", (e) =>
      if $(e.target).hasClass('grid-canvas')
        e.preventDefault()

        if @grid.getEditController().commitCurrentEdit()
          @trigger "table:leave_edit_mode"

    @trigger "table:count", @getLength()

  block: -> @blocked = true

  unblock: -> @blocked = false if @blocked

  resize: (height, width) ->
    return unless @grid
    @.$el.find(@$container).css('height', height) if _.isNumber(height)
    @.$el.find(@$container).css('width', width) if _.isNumber(width)

    @grid.resizeCanvas()
    @grid.autosizeColumns()

  getLength: ->
    if @collection.origModels then @collection.origModels.length else @collection.length

  clearSelection: ->
    @grid.setSelectedRows []
    @grid.resetActiveCell()

  setSelectedRows: (items) ->
    rows_to_select = _.map items, (item) =>
      @collection.indexOf(item)

    @grid.setSelectedRows rows_to_select
    @grid.scrollRowIntoView rows_to_select[0]

  getSelectedRows: ->
    $ @$container
    .find ".slick-row:has(.slick-cell.selected)", @grid.getCanvasNode()

  # slickgrid think row was selected
  # while there is no visual selection
  # and positive 'selectable' flag in metadata
  #
  # @param byClass [ Boolean ] search by class?
  # @return    [ Array   ] selected models
  #
  getSelectedModels: (byClass = false) ->
    selected = _.map (byClass and @ or @grid).getSelectedRows(), (item) =>
      i = if byClass then $(item).index() else item
      @collection.at i

    if selected.length and selected[0] isnt undefined then selected else []

  setIndeterminateCheckboxes : (models) ->
    indexes = _.map models, (model) =>
      @collection.indexOf model

    $rows = $ _.sortBy (@$el.find ".slick-row"), (el) ->
      parse-int el.style.top

    $rows.filter (i) ->
      i in indexes
    .find "[type=checkbox]"
    .parent()
    .addClass "indeterminate"

  getIndeterminateCheckboxesModels : ->
    rows_indeterminate_els = @$el.find ".indeterminate"
      .closest ".slick-row"

    rows_els = _.sortBy (@$el.find ".slick-row"), (el) ->
      parse-int el.style.top

    indexes = []
    _.each rows_els, (row_el, i) ->
      if row_el in rows_indeterminate_els
        indexes.push i

    _.map indexes, (i) =>
      @collection.at i
