"use strict"

helpers = require "common/helpers.coffee"
require "fancytree"

exports.ResourceListsEmpty = class ResourceListsEmpty extends Marionette.ItemView

  className: 'empty-block__message'

  template: 'lists/resource_list_empty'

exports.ResourceLists = class ResourceLists extends Marionette.ItemView

  template: "lists/resource_lists"

  className: "sidebar__content"

  ui:
    tree                : '#resource_lists'
    toolbar_create      : '.toolbar__actions [data-action=create_resource_list]'
    toolbar_edit        : '.toolbar__actions [data-action=edit_resource_list]'
    toolbar_delete      : '.toolbar__actions [data-action=delete_resource_list]'
    toolbar_policy      : '.toolbar__actions [data-action=create_resource_list_policy]'

  triggers:
    "click .toolbar__actions [data-action=create_resource_list]"            : "create"
    "click .toolbar__actions [data-action=edit_resource_list]"              : "edit"
    "click .toolbar__actions [data-action=delete_resource_list]"            : "delete"
    "click .toolbar__actions [data-action=create_resource_list_policy]"     : "create_policy"

  events:
    "click .fancytree-container"                                            : "clearSelection"

  collectionEvents:
    'reset'         : 'reload'
    'remove'        : 'deleteNode'
    'change'        : 'changeNode updateToolbar'
    'add'           : 'addNode'


  initialize: ->
    super()

  _clearSelection: ->
    @tree.rootNode.visit (node) ->
      node.setFocus(false)
      node.setActive(false)

    @updateToolbar()

    @trigger 'select', null

  clearSelection: (e) ->
    if $(e.target).hasClass('fancytree-container')
      e.preventDefault()
      e.stopPropagation()

      @_clearSelection()

  reload: ->
    @tree.reload()

  deleteNode: (model) ->
    node = @tree.getNodeByKey(model.id)
    parent = node.getParent()

    if parent.countChildren(false) is 1
      selecting_node = parent
    else
      if node.getPrevSibling()
        selecting_node = node.getPrevSibling()
      else
        selecting_node = node.getNextSibling()

    node.remove()
    parent.sortChildren()

    if selecting_node is @tree.rootNode
      @_clearSelection()
    else
      selecting_node.setActive(true)

  changeNode: (model, value, options) ->
    changed = model.changedAttributes()

    if 'DISPLAY_NAME' of changed

      node = @tree.getNodeByKey(model.id)
      node = $.extend node, model.getItem()

      node.renderTitle()

    @updateToolbar()

  addNode: (model) ->
    new_node = @tree.rootNode.addChildren model.getItem()
    @tree.rootNode.sortChildren()

    new_node.setActive()

  blockToolbar: ->
    @ui.toolbar_create.prop("disabled", true)
    @ui.toolbar_edit.prop("disabled", true)
    @ui.toolbar_delete.prop("disabled", true)
    @ui.toolbar_policy.prop("disabled", true)

  updateToolbar: ->
    @blockToolbar()

    selected = @collection.get(@getActiveNode()?.key)

    if selected
      if helpers.can({type: 'resource', action: 'edit'})
        @ui.toolbar_policy.prop("disabled", false)

      if helpers.can({type: 'resource', action: 'edit'})
        @ui.toolbar_create.prop("disabled", false)
        @ui.toolbar_edit.prop("disabled", false)

      if helpers.can({type: 'resource', action: 'delete'})
        @ui.toolbar_delete.prop("disabled", false)
    else
      if helpers.can({type: 'resource', action: 'edit'})
        @ui.toolbar_create.prop("disabled", false)

  onShow: ->
    @ui.tree.fancytree
      source: @collection.getItems
      debugLevel: 0
      activate: (event, data) =>
        @updateToolbar()
        @trigger 'select', data.node.key

      dblclick: (event, data) =>
        if helpers.can({type: 'resource', action: 'edit'})
          @trigger 'edit'
      init: =>
        if @options.selected
          @ui.tree.fancytree('getTree').activateKey @options.selected
        else
          root_node = @ui.tree.fancytree('getRootNode')
          if root_node.children.length
            root_node.children[0].setActive()

    @tree = @ui.tree.fancytree('getTree')

    @updateToolbar()

  select: (model) ->
    @tree.activateKey model.id

  getActiveNode: -> @tree.getActiveNode()
