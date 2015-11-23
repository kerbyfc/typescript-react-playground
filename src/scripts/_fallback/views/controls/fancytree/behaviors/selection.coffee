"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeSelectionBehavior extends FancyTreeBehavior

  methods: {
    "getSelectedNodes"
    "getSelectedFolders"
    "getSelectedItems"
  }

  ###########################################################################
  # INTERFACE

  ###*
   * Get selected (e.g. via checkboxes) tree nodes
   * @return {Array} - nodes
  ###
  getSelectedNodes: ->
    @tree?.getSelectedNodes() or []

  ###*
   * Get selected folders
   * @return {Array} - folder nodes
  ###
  getSelectedFolders: ->
    _.filter @getSelectedNodes(), @view.isFolder

  ###*
   * Get selected items
   * @return {Array} - item nodes
  ###
  getSelectedItems: ->
    _.reject @getSelectedNodes(), @view.isFolder
