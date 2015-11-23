"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeVisitorBehavior extends FancyTreeBehavior

  methods: {
    "visit"
    "visitItems"
    "visitFolders"
  }

  ###*
   * Detect options in arguments list when
   * arguments has to support optional object as first argument
   * and callback as last argument.
   * Also supports callback in options argument
   * @param {Array} @arguments
   * @return {Array} [options, callback]
  ###
  _decoupleArguments = (args) ->
    args  = _.toArray(args)
    first = _.first(args)
    last  = _.last(args)

    options  = if _.isObject(first) then first else {}
    callback = if _.isFunction last then last else options.callback

    [options, callback]

  _visitFilter = (view, node, filter, args) ->
    [options, callback] = _decoupleArguments args

    options.callback = (node) ->
      if filter(node)
        callback arguments...

    view.visit node, options

  _makeVisitor = (options, callback) ->
    level      = null
    breaked    = false
    startLevel = null

    (node) ->

      if not breaked

        proper =
          level : not options.levels? or node.getLevel() in options.levels
          depth : not options.depth? or depth < options.depth

          # works separatelly with _visitFilter
          filter: not _.isFunction(options.filter) or options.filter(node)

        if proper.filter and proper.level and proper.depth

          _level = node.getLevel()
          startLevel ?= _level

          if _level isnt level
            level = _level
            depth = level - startLevel + 1

          if callback(node, depth) is false
            breaked = false

        else
          false

  ###########################################################################
  # INTERFACE

  ###*
   * Visit nodes and apply callback
   * @param  {FancytreeNode|String} node - node or node key
   * @param  {Function} callback - function to call for each nested node
   * @return {FancytreeNode|Null} node or null if it wasnt found
  ###
  visit: (node, args...) ->
    [options, callback] = _decoupleArguments args

    if not _.isFunction callback
      throw new Error("FancyTree#visit expects callback to be passsed")

    if node = @view.getNode node
      node.visit _makeVisitor(options, callback), options.self or false

    node

  visitItems: (node, args...) ->
    filter = (node) =>
      not @view.isFolder(node)
    _visitFilter @view, node, filter, args

  visitFolders: (node, args...) ->
    filter = (node) =>
      @view.isFolder(node)
    _visitFilter @view, node, filter, args
