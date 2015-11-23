"use strict"

require "fancytree"

behaviorClasses =
  activity   : require "./behaviors/activity.coffee"
  dnd        : require "./behaviors/dnd.coffee"
  expander   : require "./behaviors/expander.coffee"
  node       : require "./behaviors/node.coffee"
  search     : require "./behaviors/search.coffee"
  selection  : require "./behaviors/selection.coffee"
  visitor    : require "./behaviors/visitor.coffee"

###*
 * Universally light-weight tree view, that uses fancytree.
 *
 * Next methods might be implemented:
 *  - getSource
 *
 * Public methods are wrapped to be requirable by App.reqres
 *  - getActive[Item/Folder/Node]
 *  - getSelected[Item/Folder/Node]
 *  - others...
 *
 * @note Next constructor arguments are required: <String/jQuery> container
 * @note Next properties must be implemented: <String> scope
 * @note See methods might me defined to handle tree events se _buildTree
 *
 * @example extending
 *     class ReportsTreeView extends FancyTree
 *
 *       # to be able to handle events by App.vent "reports:tree:<event>"
 *       scope: "reports"
 *
 *       onNodeActivate: (node, data) ->
 *         console.log data.model.id, data.attrs.DISPLAY_NAME
 *
 * @example instantiating
 *     tree = new ReportsTreeView
 *       container: ".tree-view__container"
 *
 * @example add handlers
 *     tree.onFolderSelect = (node, data) -> ...
 *
 * @example listen events
 *     App.vent.on "reports:tree:item:select", (node, data) -> ...
 *
 * @see views/controls/fancytree/*.coffee
 * @example Create extension
 *
 *    # my_tree.coffee
 *    couter = require(...counter.coffee)
 *
 *    class MyTree extends FancyTree
 *
 *     extensions: _.extend FancyTree::extensions,
 *      counter: counter
 *
 *     ...
 *
 *     # counter.coffee
 *
 *     class CounterFancyTreeExtention
 *
 *       # you can pass options to extension via options.counter
 *       # and merge them with defaults
 *       defaults:
 *         counter: {}
 *
 *       contructor: (view, options = {}) ->
 *        ...
 *
 *       # use fancytree virtual methods to
 *       # handle fancytree events
 *       onNodeClick  : -> ...
 *       onItemSelect : -> ...
 *
 * @note LayoutView is used as it's more extensible
 *
###
class FancyTree extends Marionette.LayoutView

  ###*
   * Default fancytree settings
   * @type {Object}
  ###
  defaults:
    checkbox   : true
    icons      : false
    selectMode : 3
    paths:
      # paths to model (in node data)
      # to interract with
      # @note required for some behaviors
      model: "attrs.model"

  methods: {
    "rebuild"
  }

  behaviorClasses: behaviorClasses

  # default behaviors
  behaviors: ->
    node      : {}
    visitor   : {}
    activity  : {}
    expander  : {}
    selection : {}

  ###*
   * Properties to be checked while instantiation
   * @type {Array}
  ###
  requiredProps: [
    "scope"
    "container"
  ]

  ###*
   * Validate self, register handlers for application event bus,
   * instantiate extensions
   * @throws {Error} If required props are missing
   * @param  {Object} options = {}
  ###
  constructor: (options = {}) ->
    # extend & override default fancytree options
    options  = _.extend {}, (@options or {}), options
    @options = _.defaults {}, options, _.result @, 'defaults'

    # setup required props
    for prop in @requiredProps
      if options[prop]
        @[prop] = options[prop]
      unless @[prop]
        throw new Error "FancyTree: `#{prop}` must be specified
          or passed as option"

    # define view methods
    for method, reqres in @methods
      reqres = _.kebabCase(method).replace /\-/g, ":"
      view._defineMethod _.camelCase(method), reqres, @[method]

    # make behaviors hash
    @behaviors = _.reduce _.result(@, 'behaviors'), (acc, options, behavior) =>
      acc[behavior] =
        if behaviorClass = @behaviorClasses[behavior]
          _.extend {}, options, behaviorClass: behaviorClass
        else
          options
      acc
    , {}

    super

  ###*
   * Build tree on show
  ###
  onShow: ->
    @_rebuild()

  ###########################################################################
  # PRIVATE

  ###*
   * Create tree event handler
   * @param  {String} eventSign - "on/before:event"
  ###
  _createEventHandler: (eventSign) =>
    (e, data, node = data.node) =>
      if e.type.match "click"
        e.stopImmediatePropagation()
      type = @isFolder(node) and "folder" or "item"
      [ moment, event ] = eventSign.split ":"
      @_triggerInteractionEvent moment, event, node, data, type, e

  ###*
   * Trigger event with App.vent bus, call proper handler
   * @example do things before and after item node selection
   *     tree.on "before:node:select"
   *     tree.on "before:item:select"
   *     tree.on "node:select"
   *     tree.on "node:item:select"
   * @param  {String} moment - "on"/"before"
   * @param  {Event} event
   * @param  {Array} args...
  ###
  _triggerInteractionEvent: (moment, event, args...) ->
    type   = args[2]
    prefix = moment is "before" and "before:" or ""

    # trigger events
    @triggerMethod "#{prefix}node:#{event.toLowerCase()}", args...
    @triggerMethod "#{prefix}#{type}:#{event.toLowerCase()}", args...

  triggerMethod: (args...) ->
    super
    App.vent.trigger "#{@scope}:tree:#{_.first args}"

  ###*
   * Instantiate fancytree
  ###
  _buildTree: ->
    container = $ @container

    return unless container.length

    handlers = _.reduce [
      "on:select" # on[Node/Item/Folder]Select method
      "on:activate"
      "on:deactivate"
      "on:focus"
      "on:blur"
      "on:expand"
      "on:collapse"
      "on:click"
      "on:dblclick"
      "on:lazyLoad"
    ], (acc, event) =>
      acc[_.last event.split ":"] = @_createEventHandler event
      acc
    , {}

    # if handler was not specified by view,
    # but registered by extension,
    # then extend handlers with them
    for extension in _.values @extensions
      if _handlers = extension.registerHandlers?()
        for handler, event of _handlers
          unless handlers[handler]
            handlers[handler] = @_createEventHandler event

    options = _.extend @options, handlers,
      source: =>
        source = @getSource()
        @triggerMethod "getSource", source
        source

      # # special handler naming convention
      removeNode     : @_createEventHandler "on:remove"
      renderNode     : @_createEventHandler "on:render"

      # # before[Node/Item/Folder]Select method
      beforeSelect   : @_createEventHandler "before:select"
      beforeExpand   : @_createEventHandler "before:expand"
      beforeActivate : @_createEventHandler "before:activate"

    @log ":options", options
    container.fancytree options

    if @options.autoSort
      # this class disables arrows while drag'n'drop
      container.children(":first").addClass "_autoSort"

    @tree = container.fancytree 'getTree'
    @triggerMethod "build", @tree

  _defineMethod: (methodName, reqres, implementation, context = @) ->
    # If method exists in view, it shouldn't be overriden by extension,
    # instead, in this case methods, defined by view class
    # overrites method that was defined by extension)
    @[methodName] ?= ->
      implementation.apply context, arguments

    App.reqres.setHandler "#{@scope}:tree:#{reqres}", @[methodName]

  ###*
   * Rebuild tree, reactivate currently active node
  ###
  _rebuild: ->
    unless @tree
      @_buildTree()

    else
      active = @getActiveNode()
      @tree.reload()

      # try to activate node after rebuild
      # if there are no active node right after reload
      if active and not @getActiveNode()
        if node = @getNode active.key
          node.setActive true, noEvents: true

      @trigger "rebuild", @tree

  ###########################################################################
  # PUBLIC

  ###*
   * Check if node is a folder node
   * @param  {FancytreeNode} node
   * @return {Boolean}
  ###
  isFolder: (node) ->
    node.folder

  rebuild: ->
    @_rebuild()

  getSource: -> []

module.exports = FancyTree
