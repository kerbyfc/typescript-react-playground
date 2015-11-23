"use strict"

helpers = require "common/helpers.coffee"
require "common/entry.coffee"
require "views/controls/tree_view.coffee"
require "views/controls/dialog.coffee"

App.Views.Controls ?= {}

class App.Views.Controls.FancyTree extends Marionette.ItemView

  template: 'controls/fancytree'

  events: ->
    "click"            : "onClick"
    "keyup @ui.search" : 'applyFilter'
    "click @ui.filter" : 'applyFilter'

  ui: ->
    tree    : "[data-region=tree]"
    message : "[data-ui=message]"
    search  : "[name=search]"
    filter  : "[data-filter]"

  collectionEvents: ->
    request: (collection) ->
      if not collection.cid and not collection.length
        @ui.message
        .text App.t "global.loading"
        .show()

    "sync add remove": ->
      if @collection.length
        @ui.message
        .hide()
      else
        @ui.message
        .text App.t "global.empty"
        .show()

    reset: -> @tree.reload()

    change: (model, value, options) ->
      changed = model.changedAttributes()
      pid   = model.parentIdAttribute

      return unless changed
      if pid of changed
        sourceNode = @tree.getNodeByKey model.id
        parentNode = @getParentNode model.get pid

        sourceNode.moveTo parentNode, 'child'
        parentNode.sortChildren()
        parentNode.setExpanded true

      if model.enabledAttribute of changed or
      model.nameAttribute of changed or
      model.countAttribute of changed
        node = @tree.getNodeByKey model.id
        if node
          node = $.extend node, model.getItem()

          node.renderStatus()
          node.renderTitle()

    add: (model) ->
      pid = model.parentIdAttribute
      parentNode = @getParentNode model.get pid

      newNode = parentNode.addChildren model.getItem()
      parentNode.sortChildren()

      newNode.setActive()

    remove: (model) ->
      node   = @tree.getNodeByKey model.id
      parent = node.getParent()

      if parent.countChildren(false) is 1
        selectingNode = parent
      else
        selectingNode = node.getPrevSibling?() or node.getNextSibling()

      node.remove()
      parent.sortChildren()

      if selectingNode is @tree.rootNode
        @collection.trigger 'select', @collection.getRootModel?()
      else
        selectingNode.setActive true

  getParentNode: (parentId) ->
    root = @collection.getRootModel()

    # если нет родительской группы (ex: Классификатор, дерево категорий)
    return @tree.rootNode if not parentId
    # в случае родительской группы (ex: Текстовые объекты, ОЗ и др)
    return @tree.rootNode if root and root.id and root.id is parentId

    destNode = @tree.getNodeByKey parentId

  clearSelection: ->
    @tree.rootNode.visit (node) ->
      node.setFocus false
      node.setActive false

    @collection.trigger 'select', @collection.getRootModel()

  onClick: (e) ->
    return if e.target isnt @ui.tree.get(0)
    e.preventDefault()
    e.stopPropagation()

    @clearSelection()

  onClose: -> @collection.reset()

  initialize: (o) ->
    {@type, @data, @filter, @checkbox} = o

    # TODO: реализовать без определения методов, вынести
    # в бехевиор тулбар и т д
    @collection.getSelectedModels = => @getSelectedModels()
    # DEPRECATED: выпилить когда будут реализованы методы обхода
    # дерева моделей на уровне коллекции
    @collection.getNodeByKey = => @tree.getNodeByKey arguments...

    # TODO: копипаст, выпилить в дальнейшем;
    proto = @collection.model::
    data = _.map @data, (model) -> model.content or model

    @selected = new Backbone.Collection data,
      model: Backbone.Model.extend
        idAttribute   : proto.idAttribute
        nameAttribute : proto.nameAttribute

    @type = App.entry.getConfig(proto)?.type unless @type

    # end TODO: копипаст, выпилить в дальнейшем;

    @listenTo App.Session.user, "message:import", (data) =>
      if data.status is 'success' and
      data.module is App.currentModule?.moduleName.toLowerCase()
        @clearSelection()
        @collection.reset()
        @collection.fetch()

    @config = _.result @collection, 'config'

    @config = _.extend @config,
      source         : @collection.getItems
      type           : proto.type
      entryType      : proto.entryType
      countAttribute : proto.countAttribute

      select: => @trigger "change:data", @

      init: =>
        rootNode = @ui.tree.fancytree 'getRootNode'
        rootNode.sortChildren()

        _.each rootNode.getChildren(), (node) -> node.setExpanded true

        if @data?.length
          @getTree().visit (node) =>
            node.setSelected true if _.find @data, ID: node.key

      activate: (e, data) => @collection.trigger 'select', @collection.get(data.node.key)

      dblclick: (e, data) =>
        if @tree.rootNode isnt data.node.parent
          parent = @collection.get data.node.parent.key

          if (parent and parseInt(parent.get("ENABLED"), 10) is 0)
            return

        @trigger 'edit'

    if @checkbox
      @config.selectMode = 2
      @config.checkbox   = true

    if @filter
      @config.extensions.push "filter"
      @config.filter = mode: "hide"

  applyFilter: (e) =>
    e?.preventDefault()

    $el = $ e.currentTarget
    filter = $el.data 'filter'

    if not _.isUndefined filter
      @ui.filter.removeClass 'active'
      $el.addClass 'active'
    else filter = @ui.filter.filter('.active').data 'filter'

    query  = @ui.search.val()
    @clearSelection()

    if query is '' and (filter is 'all' or filter is undefined)
      @tree.clearFilter()
    else
      @tree.filterNodes (node) ->
        if ( query is '' or ( node.title.toLowerCase().indexOf(query.toLowerCase()) > -1 ) )
          return true if _.isUndefined filter

          if ( filter is 'all' or node.data.ENABLED is filter )
            true
          else
            false

        else false

  select: (model, activate = true) ->
    if model.isRoot()
      return @clearSelection()

    if node = @tree.getNodeByKey model.id
      if activate
        node.setActive()
      else
        node.setActive true, noEvents: true

  getActiveNode: -> @tree.getActiveNode()

  getSelectedModels: ->
    id    = @getActiveNode()?.key
    model = @collection.get id
    return [ model ] if model and not model.isRoot()
    null

  onShow: ->
    @ui.tree.fancytree @config

    @tree = @getTree()

  getTree: -> @ui.tree.fancytree 'getTree'

  get: ->
    models = @getTree().getSelectedNodes()

    return [] unless models.length
    _.compact _.map models, (model) =>
      # return if _.find models, key: model.parent.key
      id = model.key

      TYPE    : @options.type
      ID      : id
      NAME    : model.title
      content : @collection.get(id).toJSON()

class App.Views.Controls.Tree extends App.Views.Controls.TreeView

  template: 'controls/tree'

  initialize: (o) ->
    config = o.config if o?.config
    config = _.result @, 'config' unless config
    super config

    if o.data?.length
      data = _.clone o.data
      @on "treeview:postinit", (rootNode) =>
        @checkNodes data

      @on "treeview:lazyloaded", (node) ->
        _.each [node].concat(node.children), (node) ->
          node.setSelected() if _.indexOf(_.pluck(data, "ID"), node.key) isnt -1

    @on "treeview:check", (node, select) =>
      @trigger "change:data", @

  get: ->
    models = @getChecked()
    return [] unless models.length

    _.compact _.map models, (model) =>
      # return if _.find models, key: model.parent.key
      id = model.key

      TYPE    : @options.type
      ID      : id
      NAME    : model.title
      content : @collection.get(id).toJSON()

class App.Views.Controls.SidebarTree extends App.Views.Controls.FancyTree

  template: "controls/sidebar_tree"

  templateHelpers: ->
    proto = @collection.model::
    entryType = proto.entryType
    type = proto.type
    header = App.t "select_dialog.#{@type}",
      context : 'header'
      items : App.t("select_dialog.#{entryType}_plural_5").toLowerCase()

    placeholder = App.t "global.search"
    placeholder += ' '
    placeholder += App.t "select_dialog.#{@type}_placeholder"

    isFilter    : @buttons.indexOf('activate') isnt -1
    placeholder : placeholder
    header      : header
    type        : @type
    buttons     : @buttons
    search      : true

  className: "sidebar__content"

  ui: -> _.extend super, toolbar: '[data-ui=toolbar]'

  behaviors: ->
    collection = @options.collection
    proto = collection.model::
    @type = proto.type
    @buttons = _.result collection, 'buttons'
    o = container: "#{@ui().toolbar}[data-type=#{@type}]"

    behaviors = Toolbar : _.extend o, _.result(@options.collection, 'toolbar')

    if @options.collection.model::can 'move'
      behaviors.Drag = behaviorClass: App.Behaviors.Tree.Drag

    behaviors
