"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeExpanderBehavior extends FancyTreeBehavior

  methods: {
    "expand"
    "collapse"
    "toggle"
  }

  ###########################################################################
  # INTERFACE

  ###*
   * Expand node
   * @param  {String} keyOrNode - node or it's key
   * @param  {Object} opts = {}
  ###
  expand: (keyOrNode, opts = {}) ->
    if node = @view.getNode keyOrNode
      node.setExpanded true, opts
      return node
    null

  ###*
   * Collapse node
   * @param  {String} keyOrNode - node or it's key
   * @param  {Object} opts = {}
  ###
  collapse: (keyOrNode, opts = {}) ->
    if node = @view.getNode keyOrNode
      node.setExpanded false, opts
      return node
    null

  ###*
   * Toggle node expansion state
   * @param  {String} keyOrNode - node or it's key
   * @param  {Object} opts = {}
  ###
  toggle: (keyOrNode) ->
    if node = @view.getNode keyOrNode
      node.toggleExpanded()
