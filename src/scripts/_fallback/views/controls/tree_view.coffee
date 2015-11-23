"use strict"

async = require "async"
require "fancytree"

App.Views.Controls ?= {}

class App.Views.Controls.TreeView extends Marionette.ItemView

  tree_view_container: ".tree_view"

  template: 'controls/tree'

  _sort_children_comparator: (node1, node2) ->
    title1 = node1.title.toLowerCase()
    title2 = node2.title.toLowerCase()

    if title1 > title2
      1
    else if title1 < title2
      -1
    else
      0

  initialize: (config) ->
    @config = config.config or config
    @collection.active_model ?= {}

    if @config.resize_container?
      @_resize_init(
        @config.resize_container_height_padding
        @config.resize_container_width_padding
      )

    @listenTo @collection, "add", (model, collection) ->
      data = @_prepareNodeData model.toJSON()

      parent_id = model.get_parent_id?()  or  model.get(@config.dataParentField)
      if parent_id
        @load_node(
          collection.get(parent_id).get(@config.data_key_path)
          true
        )
        .done(
          (node) =>
            node.lazy = true
            @add(data, node)

        )
      else
        @add(
          data
          null
        )

    @listenTo @collection, "destroy", (model) ->
      @load_node(
        model.get(@config.data_key_path)
        true
      )
      .done(
        (node) => @delete(node)
      )

    if @config.dataTooltipField
      @listenTo @collection, "change:" + @config.dataTooltipField, (model) =>
        if @config.dataTooltipLength
          tooltip = model.get(@config.dataTooltipField)?.substring(0, @config.dataTooltipLength - 1)
        else
          tooltip = model.get(@config.dataTooltipField)

        @edit path: model.get(@config.data_key_path),
          tooltip: tooltip

    @listenTo @collection, "change:" + @config.dataTextField, (model) ->
      @edit path: model.get(@config.data_key_path),
        title: model.get(@config.dataTextField)

    @listenTo @collection, "change:" + @config.dataParentField, (model) ->
      parent_id = model.get_parent_id?()  or  model.get(@config.dataParentField)
      source_node_state = @load_node(
        model.previous(@config.data_key_path)
      )
      if parent_id
        dest_node_state = @load_node(
          model.collection.get(parent_id).get(@config.data_key_path)
        )
      else
        dest_node_state  = null

      $.when(
        source_node_state
        dest_node_state
      )
      .done(
        (source_node, dest_node) =>
          source_node.data[@config.data_key_path] = model.get(@config.data_key_path)

          if source_node.data.drag_action is "move"
            @move source_node, dest_node, "over"
          else if source_node.data.drag_action is "copy"
            @copy source_node, dest_node

      )

    @listenTo @collection, "change:" + @config.dataChildsField, (model) ->
      @load_node(
        model.get(@config.data_key_path)
      )
      .done(
        (node) ->
          if model.get('CHILDREN_COUNT') is 0
            node.data.lazy = false
          node.render()
      )

    @listenTo @collection, "change:" + @config.dataIconField, (model) ->
      if model.previous(@config.dataIconField) isnt model.get(@config.dataIconField)
        @edit path: model.get(@config.data_key_path),
          iconclass: @config.icons[model.get(@config.dataIconField)]

    @on "treeview:select", (node) ->
      @collection.active_model = @collection.get node.key

  _prepareNodeData: (elem) ->
    nodeData =
      title:
        if @config.locale and @config.locale[elem[@config.dataTextField]]
          @config.locale[elem[@config.dataTextField]]
        else
          _.escape elem[@config.dataTextField]
      lazy: elem[@config.dataChildsField] isnt 0
      key: elem[@config.dataKeyField]
      selected: @config.checked and _.where(@config.checked, {DATA: elem[@config.dataKeyField]}).length isnt 0
      children: elem.children if elem.children
      expanded: elem.expand
      drag_action: if typeof @config.set_drag_action is "function" then @config.set_drag_action(elem) else "move"

    if @config.dataUnselectableFields
      nodeData['unselectable'] = @config.dataUnselectableFields(elem)

    if @config.dataIconField
      if _.isFunction(@config.dataIconField)
        nodeData['iconclass'] = @config.icons[@config.dataIconField(elem)]
      else
        nodeData['iconclass'] = @config.icons[elem[@config.dataIconField]]

    if @config.dataTooltipField
      if @config.dataTooltipLength
        nodeData['tooltip'] = elem[@config.dataTooltipField]?.substring(0, @config.dataTooltipLength - 1)
      else
        nodeData['tooltip'] = elem[@config.dataTooltipField]

    if @config.dataClassField
      nodeData['extraClasses'] = @config.class[elem[@config.dataClassField]]

    nodeData.data = elem
    nodeData

  initTree: ->
    fetch_data = {}

    fetch_data[@config.dataKeyTitle] = null

    if @collection.source
      fetch_data['source'] = @collection.source

    if @config.sorting
      fetch_data.sort = {}
      fetch_data.sort[@config.dataTextField] = 'asc'

    if @tree_view_container.fancytree()
      @tree_view_container.fancytree('destroy')
      @tree_view_container.empty()

    # Тащим коллекцию - для lazy дерева, только узлы первого
    @collection.fetch
      silent: true
      reset: true
      data: fetch_data
      success: (collection, response, options) =>
        init_data = []
        load_init_data = []
        node_data = if @config.data_fync then @config.data_fync(response) else response.data

        # Выгружаем в DOM из полученных данных только самое необходимое
        $.each node_data, (ind, elem) =>
          init_data.push @_prepareNodeData(elem)

        @tree_view_container.fancytree
          extensions    : ['dnd']

          autoActivate  : false
          checkbox      : @config.checkbox or false
          source        : init_data
          debugLevel    : 0
          selectMode    : @config.selectMode or 2
          strings       :
            loadError   : App.t "global.load_error"

          render: =>
            @triggerMethod "treeview:render"
          dblclick: (event, data) =>
            @triggerMethod "treeview:dblclk", data.node
          select: (e, data) =>
            @triggerMethod "treeview:check", data.node, data.node.isSelected()
          beforeActivate: (flag, node) =>
            @triggerMethod "treeview:before:select", arguments...
          activate: (event, data) =>
            @triggerMethod "treeview:select", data.node
          lazyLoad: (event, data) =>
            node = data.node

            dfd = new $.Deferred()

            fetchOptions =
              data: fetch_data
              remove: false
              silent: true
              merge: true
              add: true
              success: (collection, response, options) =>
                is_focused = node.hasFocus()
                response_data = if @config.data_fync then @config.data_fync(response) else response.data
                data_for_node = _.map response_data, (elem) =>
                  @_prepareNodeData(elem)

                dfd.resolve data_for_node

                node.sortChildren @_sort_children_comparator, true
                node.setFocus() if is_focused

              error: (collection, response, options) ->
                node.setStatus('error',
                  message : ""
                  details : ""
                )

            fetchOptions.data[@config.dataKeyTitle] = node.data[@config.dataLoadField]

            # Тащим данные для нужной группы с дозагрузкой в коллекцию
            @collection.fetch fetchOptions

            data.result = dfd.promise()

          loadChildren: (event, data) ->
            if data.node.tree.selectMode is 3
              data.node.fixSelection3AfterClick()
          init: (event, data) =>
            rootNode = data.tree.getRootNode()
            @tree = @tree_view_container.fancytree('getTree')

            if rootNode.getChildren()
              async.each rootNode.getChildren(), (node, callback) ->
                if node.isLazy()
                  node.load()
                  .then ->
                    node.setExpanded()
                    callback()
                else
                  node.setExpanded()
                  callback()

              , (err) =>
                @triggerMethod "treeview:postinit", data.tree
          dnd:
            preventVoidMoves: true
            preventRecursiveMoves: true
            dragStart: (sourceNode, data) =>
              # This function MUST be defined to enable dragging for the tree.
              # Return false to cancel dragging of node.

              if not @config.draggable then return false

              result = true

              # Если задан handler у наследника
              # вызываем его
              if @dragHandler
                result = @dragHandler(sourceNode, data)

              return result

            dragEnter: (targetNode, data) =>
              result = ["before", "after", "over"]

              # Если задан handler у наследника
              # вызываем его
              if @dragEnterHandler
                result = @dragEnterHandler(data.node, data.otherNode, data.ui)

              return result

            dragDrop: (targetNode, data) =>
              # This function MUST be defined to enable dropping of items on
              # the tree.

              if @dragDropHandler
                @dragDropHandler data.node, data.otherNode, data.hitMode, data.ui, data.draggable

  render: ->
    super()

    if _.isString @tree_view_container
      @tree_view_container = @$(@tree_view_container)

    @initTree()

    @

  # Динамическое изменение ширины/высоты дерева при ресайзе контейнера
  _resize_init: (height_padding = 80, width_padding = 10) ->
    resize_throttled = _.throttle(
      (sizes) => @resize sizes.height - height_padding, sizes.width - width_padding
      500
    )

    if typeof @config.resize_container is 'string' or @config.resize_container instanceof String
      @config.resize_container = $(@config.resize_container)

    @config.resize_container.on "resize.treeview", (event, ui) ->
      resize_throttled(ui.size)
    @once "show", -> resize_throttled(
      height : @config.resize_container.height()
      width  : @config.resize_container.width()
    )

  # Установить у дерева ширину и высоту для возможности скролла
  resize: (height, width) ->
    @tree_view_container.height height
    @tree_view_container.width width

  copy: (sourceNode, destNode) ->
    sourceNode.setActive(false)

    copyNode = sourceNode.toDict true, (dict) ->
      delete dict.key

    if destNode.hasChildren() isnt undefined
      _node = destNode.addChildren(copyNode)
      _node.key = _node.data[ @config.dataKeyField ]
      destNode.sortChildren @_sort_children_comparator
    else
      destNode.load(true)

  move: (sourceNode, destNode, position) ->
    sourceNode.setActive(false)

    if destNode is null
      destNode = @tree.getRootNode()

    # если узел загружен, то переносим
    # иначе - просто загрузим данные
    if destNode.hasChildren() isnt undefined
      sourceNode.moveTo(destNode, position)
      destNode.sortChildren @_sort_children_comparator
      destNode.setExpanded()
      sourceNode.setActive()
    else
      sourceNode.remove()

    if sourceNode.data.isLazy
      sourceNode.load(true)

  # Добавляет узел в дерево
  # Если destNode - задан, узел добавится как предок к нему
  # если destNode не задан - узел добавится в корень TreeView
  add: (node, destNode) ->
    if destNode
      _node = @tree.getNodeByKey destNode.key
    else
      _node = @tree.getRootNode()

    if _node.hasChildren() isnt undefined
      # Если узел загружен и содержи child элементы

      _node.setExpanded()
      _n = _node.addChildren(node)
      _node.sortChildren @_sort_children_comparator
      @tree.activateKey(node.key)

      @triggerMethod "treeview:add"
    else
      # Если узел не грузили - загрузим его
      _node.load(true).done =>
        _node.toggleExpanded()

        @tree.activateKey(node.key)
        @triggerMethod "treeview:add"

  getNode: (node) ->
    @tree.getNodeByKey(node.key)

  load_node: (path, stop = false) ->
    state = $.Deferred()
    @tree.loadKeyPath(
      path.replace(/(>|\\)/g, "/")
      (node, status) ->
        switch status
          when "loaded"
            if stop  and  not node.isExpanded()
              state.reject(stopped: true)
            else
              node.makeVisible()
          when "ok"
            node.makeVisible()
            state.resolve(node)
          when "notfound"
            state.reject(notfound: true)
    )
    state

  # Set-ит  для заданного узла новые данные
  edit: (node, data) ->
    @load_node(
      node.path
    )
    .done(
      (node) =>
        _.extend node.data, data
        if data.title then node.setTitle data.title
        node.render()
        node.getParent().sortChildren @_sort_children_comparator
        @triggerMethod "treeview:change"
    )

  select: (node, callback, silent = false) ->
    @load_node(
      node.path
    )
    .done(
      (node) =>
        node.setSelected()
        node.setActive()

        callback(node) if callback

        if not silent
          @triggerMethod "treeview:selected", node
    )

  # Set-ит новые данные для заданного узла и рекурсивно для всех child-ов
  editWithChildren: (node, data) ->
    _node = @tree.getNodeByKey(node.key)

    _node.visit((node) ->
      node.data = $.extend({}, node.data, data)
      node.render()
      node.getParent().sortChildren @_sort_children_comparator

      @triggerMethod "treeview:change"

      if node.hasChildren() is undefined
        return "skip"
    , true)

  # Очищает селектирование в дереве
  clearSelection: ->
    @tree.getRootNode().visit (node) ->
      if node.isActive()
        $(node.span).removeClass("fancytree-active")
      node.setActive(false)

  getSelected: ->
    @tree.getActiveNode()

  getChecked: (stop_on_parent = false) ->
    @tree.getSelectedNodes(stop_on_parent)

  ###*
  * Get node parent
  * @return {FancytreeNode} node
  ###
  getParent: (node) ->
    _node = @tree.getNodeByKey(node.key)
    if _node
      return _node.getParent()
    else
      return null

  ###*
  * Get first level tree nodes
  * @return [FancytreeNodes] array of Fancytree nodes
  ###
  getRootNodes: ->
    @tree_view_container.fancytree('getTree').rootNode.getChildren()

  ###*
  * Check specified nodes in tree
  * @param  [FancytreeNodes] array of Fancytree nodes
  * @return none
  ###
  checkNodes: (nodes) ->
    _.each nodes, (node) =>

      @load_node(
        node.ID or node.get(@config.data_key_path)
        true
      )
      .done(
        (node) -> node.setSelected()
      )

  ###*
   * Reinit treeview
  ###
  refresh: ->
    _.defer =>
      @initTree()
      @triggerMethod "treeview:reload"

  ###*
   * Delete node from tree
   * @param  {FancytreeNode} node
   * @return {FancytreeNode} deleted node
  ###
  delete: (node) ->
    _parent = node.getParent()
    node.remove()

    # если это был последний child - убираем флаг lazy у родителя
    if not _parent.hasChildren()
      _parent.data.lazy = false
      _parent.render()

    _parent.setActive()

    @triggerMethod "treeview:remove", node
