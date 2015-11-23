FancyTree = require "views/controls/fancytree/view.coffee"

MAX_DEPTH = App.Config.reports.maxTreeDepth - 1
storage = require "local-storage"

module.exports = class ReportsTree extends FancyTree

  template: "reports/tree"
  className: "sidebar__content"
  scope: "reports"

  options:
    icons: true
    checkbox: false

  behaviors: ->
    _.extend super,
      dnd: {}

      search:
        placeholder : App.t "reports.search_placeholder"
        container   : "[data-widget='fancyTreeSearch']"

      activity:
        resetTriggers: [
          ".fancytree-container"
          ".sidebar__header"
          ".sidebar__indent"
        ]

  ui:
    edit      : "[data-action='edit']"
    delete    : "[data-action='delete']"
    cancel    : "[data-action='cancel']"
    execute   : "[data-action='execute']"
    add       : "[data-action='add']"
    addFolder : "[data-type='folder']"
    copy      : "[data-action='copy']"
    toolbar   : "[data-actions]"
    actions   : "[data-actions] button"

  events:
    "click @ui.edit"    : "_edit"
    "click @ui.delete"  : "_removeEntity"
    "click @ui.add"     : "_add"
    "click @ui.cancel"  : "_cancel"
    "click @ui.execute" : "_execute"
    "click @ui.copy"    : "_copy"

  # TODO: move to behaviors
  expanded: storage("reports:folders:expanded") or {}

  initialize: (options) ->
    @folders = options.folders
    @reports = options.reports

    Object.observe @expanded, =>
      storage("reports:folders:expanded", @expanded)

    @_beWatchful true

    @listenTo App.vent, "reports:report:change:status", @_changeReportStatus

    @on "deativate:all", ->
      App.vent.trigger "nav", "reports"

    @listenTo App.vent, "reports:cancelRun reports:executeRun", @updateToolbar

    @on "build", =>
      @visitFolders "root", (node, depth) =>
        id = node.data.model.id

        expanded = if not _.has @expanded, id
          depth < 2
        else
          @expanded[id]

        node.setExpanded expanded
        @expanded[id] = expanded

  onShow: ->
    super
    _.defer @updateToolbar

  getSource: ->
    @log ":getSource"

    folders = @folders.getNodes()
    reports = @reports.getNodes()

    # stop listening to avoid extra rebuilds
    @_beWatchful false

    map = _.reduce folders.concat(reports), (acc, node) ->
      acc[node.key] = node
      node.data.model.reports?.reset [], silent: true
      node.children = []
      acc
    , {}

    tree = []
    for key, node of map
      model = node.data.model
      if @isFolder node
        node.expanded = @expanded[model.id]

      # check if object isnt in root
      if parentId = model.get model.parentIdAttribute
        if folderNode = map["folder:#{parentId}"]

          # add to node children and to nested reports collection
          folderNode.children.push node
          if node.key.match /report/
            folderNode.data.model.reports.add model, silent: true

        else
          tree.push node

      else
        tree.push node

    # restore listening
    @_beWatchful true

    @log ":tree", tree
    tree

  onNodeActivate: (node) ->
    _.defer @updateToolbar

  onNodeDeactivate: ->
    _.defer @updateToolbar

  onFolderClick: (folder, args..., e) ->
    # Inproper element shouldn't be affected.
    # e.g. if el is expander, then click should
    # also expand node after it's collapsing
    # TODO: move to base class
    if e.originalEvent.target.className.match /icon|title/
      @expand folder

  onFolderFocus: (folder) ->
    @expand folder

  onFolderExpand: (node) ->
    @expanded[node.data.model.id] = true
    @log ":expand", node.data.model.id, @expanded

  onFolderCollapse: (node) ->
    @expanded[node.data.model.id] = false
    @log ":collapse", node.data.model.id, @expanded

  onItemActivate: (node) ->
    App.vent.trigger "nav", "reports/#{node.data.model.id}"

  onFolderActivate: (folder) ->
    @expand folder
    App.vent.trigger "nav", "reports/folders/#{folder.data.model.id}"

  ###########################################################################
  # DRAG`n`DROP EXTENSION

  ###*
   * Check drag ability
   * @implements {FancyTreeDragNDrop}
  ###
  onDragStart: (node, data) ->
    if not node.data.model.can "edit"
      return false

    @tree.rootNode.addNode
      title  : App.t "reports.tree.root"
      folder : true
      key    : "pseudo:root"
      extraClasses : "_pseudoRoot"
    , "firstChild"

    true

  ###*
   * Remove fake root node
  ###
  onDragStop: ->
    @destroyNode "pseudo:root"

  ###*
   * Restore original node title if it was temporarily changed
  ###
  onDragLeave: (node, data) ->
    @_removeDragHelperHint data

  ###*
   * Check drop ability
   * @implements {FancyTreeDragNDrop}
  ###
  onDragEnter: (node, data) ->
    @_removeDragHelperHint data

    # prevent if destination folder is parent for draggable node
    if node is data.otherNode.parent or
        node.parent is data.otherNode.parent and
        not @isFolder node
      @_setDragHelperHint data, App.t "reports.tree.already_exists"
      return false

    if node.key is "pseudo:root" and @isRootNode data.otherNode.parent
      return false

    if @isFolder data.otherNode
      sourceLevel = data.otherNode.getLevel()
      maxLevel    = sourceLevel

      # search max maxLevel of draggable folder
      data.otherNode.visit (_node) =>
        if @isFolder _node
          level = _node.getLevel()
          if level > maxLevel
            maxLevel = level

      targetFolder = if @isFolder node then node else node.parent

      delta   = maxLevel - sourceLevel
      summary = targetFolder.getLevel() + delta

      if summary > MAX_DEPTH
        @_setDragHelperHint data, App.t "reports.tree.max_depth"
        return false

    true

  ###*
   * Change dragged model FOLDER_ID/PARENT_FOLDER_ID, save model and
   * move model between collections
   * @implements {FancyTreeDragNDrop}
  ###
  onDragDrop: (node, data) ->
    @_removeDragHelperHint data

    options =
      model       : data.otherNode.data.model
      targetNode  : data.node
      targetModel : data.node.data.model
      isFolder    : @isFolder data.otherNode

    targetParentKey = if options.isFolder then "PARENT_FOLDER_ID" else "FOLDER_ID"

    _.extend options,
      oldFolder         : options.model.get targetParentKey
      targetParent      : options.targetModel?.get "FOLDER_ID"
      oldPersonality    : options.model.get "IS_PERSONAL"
      targetPersonality : options.targetModel?.get "IS_PERSONAL"

    changes = {}

    if node.key is "pseudo:root"
      options.targetParent = null

    if options.targetPersonality isnt options.oldPersonality
      changes.IS_PERSONAL = options.targetPersonality

    if options.isFolder
      changes.PARENT_FOLDER_ID = options.targetParent
    else
      changes.FOLDER_ID = options.targetParent

    @log ":move",
      changes: changes
      options: options

    # for audit
    changes.move = true

    options.model.save changes,
      wait           : true
      withoutWidgets : true
      pnotify        : false

      success: =>
        options.model.notifySuccess "move", "done"

        # show message about personality was changed
        if options.targetParent and options.oldPersonality isnt options.targetPersonality
          options.model.notifyInfo "personality", "changed"

        if parentId = options.targetParent
          @visit data.otherNode, (node) ->
            node.data.model.set "IS_PERSONAL", options.targetPersonality

        @rebuild()

      error: ->
        # if options.isFolder
        #   ... # TODO: notify folder can't be moved to private folder
        #         as it has public reports/folder of other users
        options.model.notifyError "move", "fail"

  ###########################################################################
  # PRIVATE

  ###*
   * Toggle watcing for collections rebuilds
   * @param {Boolean} enable - enable/disable watching
  ###
  _beWatchful: (enable) =>
    for collection in [@folders, @reports]
      if enable
        @listenTo collection, "rebuild", @rebuild.bind @
      else
        @stopListening collection, "rebuild"

  ###*
   * Show popover with title the node to move in and
   * optionaly the hint about the reason of the inaccessability of action

  ###
  _setDragHelperHint: (data, addon) ->
    data.ui.helper.find ".fancytree-title"
      .html data.otherNode.title + "<br/>#{addon}"

  ###*
   * Remove popover with title the node to move in and
   * optionaly the hint about the reason of the inaccessability of action
  ###
  _removeDragHelperHint: (data) ->
    data.ui.helper.find ".fancytree-title"
      .html data.otherNode.title

  ###*
   * Show execution/canceling status with spinner near proper node
   * @note spinner may be shown by _executing & _canceling modifiers
  ###
  _changeReportStatus: (data) ->
    data.node.extraClasses = @reports.resolveNodeClass data.node, data.report
    data.node.renderStatus()
    @updateToolbar()

  ###*
   * Initiate proper model redaction
   * @param  {Event} e
  ###
  _edit: (e) ->
    e.preventDefault()

    if node = @getActiveNode()
      if @isFolder node
        App.vent.trigger "nav", "reports/folders/#{node.data.model.id}/edit"
      else
        App.vent.trigger "nav", "reports/#{node.data.model.id}/edit"

  ###*
   * Copy report or folder
   * @param {jQuery.Event} e
  ###
  _copy: (e) ->
    if node = @getActiveNode()
      type = if @isFolder node then "folder" else "report"
      App.vent.trigger "reports:copy:entity", type, node.data.model,
        force: App.Config.reports.copyWithoutEditing

  ###*
   * Cleanup cached model to avoid cases when browser was crashed
   * @param {jQuery.Event} e
  ###
  _add: (e) ->
    el = $ e.currentTarget

    if href = el.data "href"

      # cleanup caches
      App.vent.trigger "reports:cleanup:storage", "report:.*", "folder:.*", "widget:.*"
      if folder = @getActiveFolder()
        App.vent.trigger "reports:remember:folder", folder.data.model.id

      App.vent.trigger "nav", el.data "href"

  ###*
   * Destroy active node model. User confirmation needs.
   * @param  {jQuery.Event} e
  ###
  _removeEntity: (e) =>
    e.preventDefault()
    node = @getActiveNode()
    type = @isFolder(node) and "folder" or "report"
    App.vent.trigger "reports:remove:entity", type, node.data.model,
      success: ->
        App.vent.trigger "nav", "reports"

  ###*
   * Start report execution
   * @param  {jQuery.Event} e
  ###
  _execute: (e) ->
    e.preventDefault()
    @getActiveNode()?.data.model.execute()
    @updateToolbar()

  ###*
   * Stop report execution
   * @param  {jQuery.Event} e
  ###
  _cancel: (e) ->
    e.preventDefault()
    @getActiveNode().data.model.cancel()

  ###########################################################################
  # PUBLIC

  ###*
   * Update toolbar buttons accessability state
   * Disable all if toolbar is disabled
   * @see #enableToolbar, #disableToolbar
  ###
  updateToolbar: =>
    disabled = @ui.toolbar.data "disabled"
    @ui.actions.attr "disabled", disabled
    if not disabled
      for action in ["delete", "execute", "cancel", "edit", "add", "copy"]
        node = @getActiveNode()
        @ui[action].each (i, el) =>
          $el = $ el

          can = if node and
              action is "add" and
              $el.data('type') is 'folder'

            # check max depth
            if folder = @getActiveFolder()
              folder.getLevel() < MAX_DEPTH+1
            else
              true

          else
            # determine if action is permitted
            do =>
              if node
                if node.data.model.can action, node
                  return true

              if action is "add" and @reports.model::can "add"
                return true
              false

          if action in ["execute", "cancel"]
            $el.toggle not node?.folder

          # disable/enable or hide/show button
          $el.attr "disabled", not can

  ###*
   * Enable toolbar buttons
   * @see #updateToolbar
  ###
  enableToolbar: ->
    @ui.toolbar.data "disabled", null
    @updateToolbar()

  ###*
   * Disable toolbar buttons
   * @see #updateToolbar
  ###
  disableToolbar: ->
    @ui.toolbar.data "disabled", true
    @updateToolbar()

  ###*
   * Get item(report) model by id
   * @param  {Number|String} id
   * @return {Object|null} node or null
  ###
  getReport: (id) ->
    @getNode("report:#{id}")?.data?.model

  ###*
   * Get folder model by id
   * @param  {Number|String} id
   * @return {Object|null} node or null
  ###
  getFolder: (id) ->
    @getNode("folder:#{id}")?.data?.model
