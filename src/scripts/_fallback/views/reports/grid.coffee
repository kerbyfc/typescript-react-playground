"use strict"

Report     = require "models/reports/report.coffee"
ReportRun  = require "models/reports/run.coffee"
Gridster   = require "common/gridster.coffee"
WidgetView = require "views/reports/widget.coffee"

config = require('settings/config.json').reports

module.exports = class WidgetGridView extends Marionette.CompositeView

  template: "reports/grid"

  className: "reports-widget-grid"

  childView: WidgetView

  childViewOptions: (model) ->
    model  : model
    report : @report
    mode   : @mode

  ###*
   * Mode to @report model type mapping
   * @type {Object}
  ###
  modes:
    edit   : Report.model
    normal : ReportRun.model

  initialize: (options) ->
    {@report, @mode} = options

    @mode ?= "normal"

    # to guarantee we can use logic based
    # on @mode in all nested views
    # TODO: think about correctness of using o@report for
    # two models in depend of usage invironment
    if @report not instanceof @modes[@mode]
      throw new Error "Widgets grid report model mismatched"

  onShow: ->
    @$el.gridster

      widget_selector : 'div'
      widget_margins  : [config.grid.margin, config.grid.margin]

      widget_base_dimensions: @_getWidgetDimension()

      max_cols: config.grid.cols

      draggable:
        handle : '.reports-widget__name'
        stop   : @_setGridOptions

      resize:
        enabled : @mode is "edit"
        resize  : @_reflow
        stop    : @_setGridOptions

      serialize_params: ($widget, data) ->
        _id    : $widget.attr('id'),
        col    : data.col,
        row    : data.row,
        size_x : data.size_x,
        size_y : data.size_y

    @gridster = @$el.data 'gridster'

    if @mode isnt "edit"
      @gridster.disable()

    @listenTo App, 'resize', @_onWindowResize

    @showCollection()

  ###*
   * Prevent adding children views
   * without gridster
  ###
  filter: ->
    @gridster?

  onAddChild: (view) ->
    if view.chart.currentView?
      @_updateWidget view
    else
      view.once "draw", (view) =>
        @_updateWidget view

  onBeforeRemoveChild: (view) ->
    # TODO: this condition currently remove consequencies,
    # so it'll be better to find reason for errors without this condition
    if view.$el.coords().grid
      @gridster.remove_widget(view.$el, true)

  #############################################################################
  # PRIVATE

  _getWidgetDimension: ->
    margins = config.grid.margin * config.grid.cols
    width = Math.round @$el.parent().width() / config.grid.cols - margins
    [ width, config.widget.height ]

  _onWindowResize: ->
    @gridster.resize_widget_dimensions
      widget_base_dimensions: @_getWidgetDimension()

  _setGridOptions: =>
    @children.each (widgetView) =>
      widgetView.model.setGridOptions @gridster.dom_to_coords widgetView.$el

  _getWidgetCoords: (widgetView) ->
    _.extend {}, widgetView.model.getGridCoords(), widgetView.getSize()

  _reflow: (..., $widget) =>
    view = @children.find (_view) ->
      _view.model.cid is $widget.data("widget")
    if view
      view.reflow()

  _updateWidget: (widgetView) =>
    cid = widgetView.$el.data "widget"

    # add widget it is't exists
    if not @gridster.$widgets.filter("[data-widget='#{cid}']").length
      @_addWidget widgetView

    @_resizeWidget widgetView

  _addWidget: (widgetView) ->
    $widget = widgetView.$el
    coords  = @_getWidgetCoords widgetView

    @gridster.add_widget $widget, coords.x, coords.y, coords.col, coords.row

    widgetView.on "draw", @_resizeWidget

    @gridster.add_resize_handle $widget
    @trigger "add", widgetView

  _resizeWidget: (widgetView, $widget, coords) =>
    $widget = widgetView.$el
    coords  = @_getWidgetCoords widgetView

    if not $widget.coords().grid
      @gridster.register_widget $widget

    @gridster.resize_widget $widget, coords.size_x, coords.size_y

    @gridster.set_widget_min_size $widget, [coords.min_size_x, coords.min_size_y]
    @gridster.set_widget_max_size $widget, [coords.max_size_x, coords.max_size_y]

    widgetView.reflow()
    @_setGridOptions()
