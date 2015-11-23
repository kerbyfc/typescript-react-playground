"use strict"

Gridster = require "gridster"
GridsterDraggable = require "gridster_draggable"

# HACK для gridster`а
# переопределяем функционал drag`а
gridsterFn = $.fn.gridster
$.fn.gridster = ->
  _savedDragFn = $.fn.drag
  $.fn.drag = (options) ->
    new GridsterDraggable @, options

  $res = gridsterFn.apply @, arguments
  $.fn.drag = _savedDragFn
  $res

Gridster::resize_widget_dimensions = (options) ->

  if options.widget_margins
    @options.widget_margins = options.widget_margins

  if options.widget_base_dimensions
    @options.widget_base_dimensions = options.widget_base_dimensions

  if options.max_cols
    @options.max_cols = options.max_cols

  @min_widget_width = @options.widget_margins[0] * 2 + @options.widget_base_dimensions[0]
  @min_widget_height = @options.widget_margins[1] * 2 + @options.widget_base_dimensions[1]

  @$widgets.each $.proxy(((i, widget) ->
    $widget = $(widget)
    @resize_widget $widget
  ), @)

  @generate_grid_and_stylesheet()
  @get_widgets_from_DOM()
  @set_dom_grid_height()

  @$el.trigger 'gridster:resizestop'

module.exports = Gridster
