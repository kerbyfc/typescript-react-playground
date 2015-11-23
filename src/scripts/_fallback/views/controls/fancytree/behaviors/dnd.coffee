"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeDndBehavior extends FancyTreeBehavior

  ###*
   * Default values for fancytree dnd extension
   * @type {Object}
  ###
  defaults:
    autoExpandMS          : 1000
    draggable             : true
    droppable             : true
    preventRecursiveMoves : true
    preventVoidMoves      : true
    focusOnClick          : false

  ###*
   * States to mixin callbacks to options
  ###
  states: [
    'start'
    'stop'
    'leave'
    'enter'
    'drop'
  ]

  # use fancytree dnd extension
  extensions: ['dnd']

  ###*
   * Merge passed and default options, create handlers
   * @param  {FancyTree} view
   * @param  {Object} options = {}
  ###
  initialize: (options = {}) ->
    for method in @states
      callback = "drag#{_.capitalize method}"
      @options[callback] = @[callback].bind @

    # merge dnd options to view options
    _.merge @view.options, dnd: @options

  ###*
   * Determine if node is draggable
   * @param  {FancytreeNode} node - node to drag
   * @param  {Object} data - node data
   * @return {Boolean} "can drag" decision
  ###
  dragStart: (node, data) ->
    if @view.onDragStart
      @view.onDragStart.call @view, node, data
    else
      true

  ###*
   * Do things on drag ends
   * @param {FancytreeNode} node - source node
   * @param  {Object} data - node data
  ###
  dragStop: (node, data) ->
    @view.onDragStop?.call @view, node, data

  ###*
   * Check ability and ways of interraction with nodes
   * @param  {FancytreeNode} node - target node
   * @param  {Object} data - node data
   * @note Return 'over', 'before, or 'after' to force a hitMode.
   * @note Return ['before', 'after'] to restrict available hitModes.
   * @return {Boolean|Array} ability decision
  ###
  dragEnter: (node, data) ->
    if @view.onDragEnter
      @view.onDragEnter.call @view, node, data
    else
      true

  ###*
   * Do things when target node leaves focus
   * @param {FancytreeNode} node - source node
   * @param  {Object} data - node data
  ###
  dragLeave: (node, data) ->
    @view.onDragLeave?.call @view, node, data

  ###*
   * Handle drop
   * @param  {FancytreeNode} dest
   * @param  {Object} data - node data
  ###
  dragDrop: (node, data) ->
    if @view.onDragDrop
      @view.onDragDrop.call @view, node, data
    else
      true
