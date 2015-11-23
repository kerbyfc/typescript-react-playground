"use strict"

require "views/controls/tree_view.coffee"

class TreeNativeDrag extends App.Views.Controls.TreeView

  # *************
  #  PRIVATE
  # *************
  _rewrite_config = ->
    _.extend @config,
      draggable : false

  _off_draggable_mousedown = ->
    @tree.off "mousedown.draggable"

  _rewrite_drag = ->
    $nodes = @$ ".fancytree-node"
    $nodes.attr "draggable", "true"
    $nodes.off "dragend", @_on_dragend_node
    $nodes.on "dragend", @_on_dragend_node

  _rebound_event_callbacks = (callbacks_arr) ->
    for cb in callbacks_arr
      _.bind cb, @


  # ***************
  #  PROTECTED
  # ***************
  _on_dragend_node: ->


  # ***********************
  #  MARIONETTE-EVENTS
  # ***********************
  onTreeviewPostinit: ->
    _rewrite_drag.call @
    _off_draggable_mousedown.call @

  onTreeviewLazyloaded: ->
    _rewrite_drag.call @


  # ***********
  #  INIT
  # ***********
  initialize: (options) ->
    [@_on_dragend_node] = _rebound_event_callbacks.call @, [@_on_dragend_node]
    _rewrite_config.call @

    super
