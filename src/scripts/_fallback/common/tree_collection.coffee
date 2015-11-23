###*
 * Class to service fancytree with data
 *
 * @method #prepareNode(node, model)
 *   Prepare node to be involved to fancytree
 *   @param {Object} node
 *   @param {Backbone.Model} model
 *
 * @method #resolveNodeClass(node, model)
 *   Add additional classes to fancytree node
 *   @param {Object} node
 *   @param {Backbone.Model} model
 *
###
module.exports = class TreeCollection extends Backbone.Collection

  rootId: null

  ###*
   * Required model properties
   * @type {Array}
  ###
  requiredModelProps: [
    'idAttribute'
    'nameAttribute'
    'parentIdAttribute'
  ]

  ###*
   * Events to be affect rebuild
   * @type {Array}
  ###
  rebuildEvents: [
    "update"
    "reset"
    "destroy"
    "change"
    "sort"
  ]

  initialize: ->
    @_validate()

    for prop in @requiredModelProps
      @_createGetter prop
    @_createGetter "activityAttribute"

    if name = @nameAttribute or @model::nameAttribute
      @on "change:#{name}", @sort

    @on @rebuildEvents.join(" "), @rebuild

    @rebuild()

  ###########################################################################
  # PRIVATE

  ###*
   * Reset state
   * @return {Objecct} tree data object
  ###
  _cleanup: ->
    @treeData = []

  ###*
   * Validate instance
   * @throws {Error} If require prop wasn't found in model
  ###
  _validate: ->
    for prop in @requiredModelProps
      if typeof @[prop] isnt "string" and
          typeof @model::[prop] isnt "string"
        throw new Error "Set #{@constructor.name}.#{prop}
          or #{@constructor.name}::model.#{prop}"

  ###*
   * Create getter for property, specified by another property
   * in model or collection
   * @param  {String} prop
   * @return {Function} getter
  ###
  _createGetter: (prop) ->
    getter = @["_get#{_.capitalize prop}"] = (model) =>
      model.get(@[prop]) or model.get(@model::[prop])
    getter

  ###*
   * Check if model is root, may be used
   * for root folder model rejection
   * @see  #_isRoot
   * @param  {[type]} model [description]
   * @return {Boolean} [description]
  ###
  _isRoot: (model) =>
    model.id is @rootId

  ###*
   * Build data tree for fancytree plugin
   * @return {Object} prepared data object
  ###
  _buildTreeData: =>
    models  = _.reject @models, @_isRoot
    data  = @_getNodes models
    dataMap = @_buildNodeMap data

    @_buildHierarchy data, dataMap

  ###*
   * Make nodes from models
   * @param  {Array} models = @models
   * @return {Array} nodes
  ###
  _getNodes: (models = @models) ->
    _.map models, (@getNode or @model::getNode)

  ###*
   * Make map to build tree
   * @param  {Array} data - nodes
   * @return {Object} data map
  ###
  _buildNodeMap: (data) ->
    _.reduce data, (map, node) ->
      map[node.data.model.id] = node
      map
    , {}

  ###*
   * Build hierarchical structure for fancytree
   * @param  {Array} data - nodes
   * @param  {Object} dataMap - data map
   * @return {Object} hierarchical structure
  ###
  _buildHierarchy: (data, dataMap) ->

    _.each data, (node) =>
      parent = dataMap[@_getParentIdAttribute node.data.model]

      if parent
        parent.children ?= []
        parent.children.push node
      else
        @treeData.push node

  ###*
   * Resolve additional classname of the node, based
   * on some model attributes, also calls abstract #resolveNodeClass
   * @see #resolveNodeClass
   * @param  {Object} node
   * @param  {Backbone.Model} model
   * @return {Object} node
  ###
  _resolveExtraClasses: (node, model) ->
    cls = ""
    if attr = @_getActivityAttribute model
      cls += if parseInt(model.get attr)
        "active"
      else
        "inactive"

    cls += (_.compact _.flatten [@resolveNodeClass? node, model]).join " "

    node.extraClasses = cls

  ###########################################################################
  # PUBLIC

  ###*
   * Rebuild tree structure
   * @return {Object} - tree data
  ###
  rebuild: (options = {}) =>
    @_cleanup()
    @_buildTreeData()
    @trigger "rebuild", @treeData unless options.silent
    @treeData

  ###*
   * Make node object from model
   * @param  {Backbone.Model} model
   * @return {Object} node object
  ###
  getNode: (model) =>
    node =
      title : @makeTitle model
      key   : @makeKey model

      data:
        attrs : @resolveNodeAttrs model
        model : model

    @_resolveExtraClasses node, model

    # Prepare node to be involved to fancytree
    @prepareNode? node, model
    node

  ###*
   * Serialize model to set node attributes
   * @param  {Backbone.Model} model
   * @return {Object} node attributes
  ###
  resolveNodeAttrs: (model) ->
    model.toJSON()

  ###*
   * Get hierarchical structure
   * @return {Object}
  ###
  getNodes: =>
    @treeData

  ###*
   * Specify node title
   * @param  {Backbone.Model} model
   * @return {String} title
  ###
  makeTitle: (model) ->
    @_getNameAttribute model

  ###*
   * Specify node key
   * @param  {Backbone.Model} model
   * @return {String|Number} unique key
  ###
  makeKey: (model) ->
    model.id
