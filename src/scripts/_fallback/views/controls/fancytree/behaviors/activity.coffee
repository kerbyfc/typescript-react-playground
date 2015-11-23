"use strict"

FancyTreeBehavior = require "views/controls/fancytree/behavior.coffee"

module.exports = class ActivityManager extends FancyTreeBehavior

  ###*
   * Css class selectors that affects on activity disabling
   * @type {Array}
  ###
  defaults:

    ###*
     * Css class selectors that affects on activity disabling
     * @override
     * @type {Array}
    ###
    resetTriggers: [ ".fancytree-container" ]

  methods: {
    "setActiveNode"
    "getActiveNode"
    "getActiveFolder"
    "getActiveItem"
    "resetNodesActivity"
  }

  onShow: ->
    for trigger in @options.resetTriggers
      el = @view.$ trigger
      # it can be parent container, so we should find it
      # only in current tree branch to avoid extra bugs
      el = el.length and el or @view.$el.closest trigger
      el.on "click", @_resetNodesActivity

  ###*
   * Unregister event handlers
  ###
  beforeDestroy: ->
    for trigger in @options.resetTriggers
      el = @$ trigger
      el = el.length and el or @$el.closest trigger
      el.off "click"

  ###########################################################################
  # PRIVATE

  ###*
   * Handle background clicks to reset active node
   * @param  {Event} e - event
  ###
  _resetNodesActivity: (e) =>
    if @_isActivityResetTrigger e.target
      @resetNodesActivity()

  ###*
   * Check if node is matched to selector
   * @param  {Event} e
   * @return {Boolean}
  ###
  _isActivityResetTrigger: (node) =>
    el = $ node
    _.any @options.resetTriggers, (trigger) ->
      el.is trigger

  ###########################################################################
  # INTERFACE

  ###*
   * Deactive current node
   * @param  {FancytreeNode} root = @tree.rootNode
  ###
  resetNodesActivity: (root = @view.tree?.rootNode) ->
    if root
      root.visit (node) ->
        node.setFocus false
        node.setActive false
      @triggerMethod "reset:nodes:activity"

  ###*
   * Return tree active node
   * @return {FancytreeNode|Null} tree node or null
  ###
  getActiveNode: ->
    @view.tree?.getActiveNode() or null

  ###*
   * Return active report
   * @return {FancytreeNode|Null} node or null
  ###
  getActiveItem: ->
    if node = @getActiveNode()
      unless node.parent
        return node
    null

  ###*
   * Return active report
   * @return {FancytreeNode|Null} node or null
  ###
  getActiveFolder: ->
    if node = @getActiveNode()
      return switch
        when @view.isFolder node
          node
        else
          if not @view.isRootNode node.parent
            node.parent
          else
            null
    null

  ###*
   * Activate/deactivate node
   * @param {String} key - node key
   * @param {Boolean} flag = true
   * @param {Object} opts = {} - for example noEvents:true
  ###
  setActiveNode: (key, flag = true, opts = {}) ->
    if node = @view.getNode key
      node.setActive flag, opts
      return node
    null
