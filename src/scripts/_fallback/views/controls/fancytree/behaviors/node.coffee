"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeNodeBehavior extends FancyTreeBehavior

  methods: {
    "getNode"
    "getNodeFolder"
    "getNodeModel"
    "destroyNode"
    "findAll"
    "isNode"
    "isRootNode"
    "find"
  }

  ###########################################################################
  # INTERFACE

  ###*
   * Get node by key
   * @param  {String} key
   * @return {FancytreeNode} node
  ###
  getNode: (key) ->
    switch
      when @isNode key
        key
      when key is "root"
        @view.tree?.rootNode or null
      else
        @view.tree?.getNodeByKey(key) or null

  ###*
   * Get closest folder for passed node
   * @param  {FancytreeNode} node
   * @return {FancytreeNode|Null} folder node or null
  ###
  getNodeFolder: (node) ->
    node.parent

  getNodeModel: (nodeOrKey) ->
    if node = @getNode nodeOrKey
      _.get(node, @view.options.paths.model)
    null

  ###*
   * Destroy node by key
   * @param  {String} key - node key
  ###
  destroyNode: (key) ->
    if node = @getNode key
      node.remove()

  isNode: (node) ->
    node instanceof @view.tree.rootNode.constructor

  isRootNode: (node) ->
    node is @view.tree.rootNode

  findAll: (filter = -> true) ->
    @tree?.findAll filter

  find: (filter = -> true) ->
    @tree?.findFirst filter
