"use strict"

class TaskView extends Marionette.ItemView

  template: "crawler/sidebar/task_view"

  className: "crawlerTask"

  templateHelpers: ->

    launchTime:
      if @model.get("lastLaunch")
        @model.get("lastLaunch").format("D.MM.YYYY, H:mm:ss")
      else
        App.t "crawler.missedlastLaunch"

  triggers:
    "click": "click"

  markAsSelected: ->
    @$el.addClass("_selected")

  markAsDeselected: ->
    @$el.removeClass("_selected")

  isSelected: ->
    @$el.hasClass("_selected")


  onShow: ->
    @listenTo @model, 'change:status', =>
      @render()

    @listenTo @model.status, 'sync', =>
      @render()


class TasksEmpty extends Marionette.ItemView

  template: 'crawler/tasks_empty'


module.exports = class TasksView extends Marionette.CompositeView

  template: "crawler/tasks"

  childViewContainer: ".crawlerTasks"

  emptyView: TasksEmpty

  className: "sidebar__content"

  childView: TaskView

  ui:
    toolbarCreateTask   : "#crawler_create_task"
    toolbarEditTask     : "#crawler_edit_task"
    toolbarDeleteTask   : "#crawler_delete_task"
    toolbarRunTask      : "#crawler_run_task"
    toolbarStopTask     : "#crawler_stop_task"
    toolbarPurgeHashes  : "#crawler_purge_hashes"
    editScanner         : "[data-action='editScanner']"

  triggers:
    "click @ui.toolbarCreateTask"   : "createTask"
    "click @ui.toolbarDeleteTask"   : "deleteTask"
    "click @ui.toolbarEditTask"     : "editTask"
    "click @ui.toolbarRunTask"      : "runTask"
    "click @ui.toolbarStopTask"     : "stopTask"
    "click @ui.editScanner"         : "editScanner"
    "click @ui.toolbarPurgeHashes"  : "purgeHashes"

  _blockToolbar: ->
    @ui.toolbarCreateTask.prop('disabled', true)
    @ui.toolbarEditTask.prop('disabled', true)
    @ui.toolbarDeleteTask.prop('disabled', true)
    @ui.toolbarRunTask.prop('disabled', true)
    @ui.toolbarStopTask.prop('disabled', true)
    @ui.toolbarPurgeHashes.prop('disabled', true)
    @ui.editScanner.prop('disabled', true)

  _updateToolbar: (selected) ->
    @_blockToolbar()

    if @collection.scanner.get('online') is "true"
      @ui.editScanner.prop('disabled', false)
      @ui.toolbarCreateTask.prop('disabled', false)

    if selected
      if selected.has('locked') and selected.has('running')
        if selected.get('locked') is "false" and selected.get('running') is 'false'
          @ui.toolbarEditTask.prop('disabled', false)
          @ui.toolbarDeleteTask.prop('disabled', false)

        if selected.get('running') is 'false'
          @ui.toolbarRunTask.prop('disabled', false)
          @ui.toolbarPurgeHashes.prop('disabled', false)
        else
          @ui.toolbarStopTask.prop('disabled', false)
      else
        @ui.toolbarEditTask.prop('disabled', false)
        @ui.toolbarDeleteTask.prop('disabled', false)
        @ui.toolbarRunTask.prop('disabled', false)
        @ui.toolbarPurgeHashes.prop('disabled', false)

  onChildviewClick: (view) ->
    @children.each (child) ->
      child.markAsDeselected()

    view.markAsSelected()

    @_updateToolbar(view.model)

    @trigger "task:selected", view.model


  select: (task) ->
    @children.each (child) ->
      child.markAsDeselected()

    @children.findByModel(task).markAsSelected()

  getSelected: ->
    if @collection.length
      _.compact @children.map (child) ->
        if child.isSelected() then child.model

  onShow: ->
    @_updateToolbar()

    @listenTo @collection, "add remove", @_updateToolbar
    @listenTo @collection, "change:locked change:status", @_updateToolbar
