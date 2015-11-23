"use strict"

async = require "async"

helpers = require "common/helpers.coffee"
style   = require "common/style.coffee"

App.Behaviors.Grid ?= {}
App.Behaviors.Tree ?= {}

class App.Behaviors.Tree.Drag extends Marionette.Behavior

  move: (s, d) ->
    source = @view.collection.get s.key
    dest   = @view.collection.get d?.key
    action = "move"

    module = App.currentModule?.moduleName
    return unless module

    className = App.Views[module]?[helpers.camelCase(@type, true) + _.capitalize(action)]
    className = className ? App.Views.Controls.DialogTreeMove

    modal = if App.modal2.currentView then App.modal2 else App.modal

    App.modal.show new className
      type   : @type
      source   : source
      dest   : dest
      action   : action
      callback : ->
        @disableButton true
        source.move dest
        modal.empty()

  onRender: ->
    collection = @view.collection

    @type = @view.type

    @listenTo collection, "move", @move

    @view.config.extensions.push "dnd" # TODO: реализовать проверку привилегий;
    @view.config.dnd =
      preventVoidMoves : true
      autoExpandMS     : 400

      preventRecursiveMoves : true

      dragStart: (node, data) ->
        data.ui.helper.append Marionette.Renderer.render "controls/drag_error"
        true

      dragEnter: -> true

      dragOver: (node, data) ->
        data.ui.helper
        .data("mode", false)

        error = data.ui.helper.find "[data-error]"
        error.text ''

        destModel = collection.get node.key
        if data.otherNode is null # перемещается не элемент дерева (термин и др.)

          if destModel is data.ui.helper.currentCategory
            # если перемещение в ту же группу -> запрещаем
            errorMessage = App.t "form.error.drag_already", context: destModel.type
            isCanMove = false
          else if not destModel.isCanContainsOnlyFolders
            # если группа с подгруппами не может содержать других объектов -> запрещаем
            if destModel.getChildrenCount()
              isCanMove = false
              errorMessage = App.t "form.error.drag_contains_subdir"
            else
              isCanMove = "over"
          else
            isCanMove = "over"

          if isCanMove
            data.ui.helper
            .removeClass style.className.drag.dropReject
            .data "mode", true
          else
            data.ui.helper
            .addClass style.className.drag.dropReject
            error.text "(#{errorMessage})"

          return isCanMove

        # если группа не может иметь подгруппы, запрещаем перемещение
        if create = _.result(collection, 'toolbar')?.create
          if create.call(collection, [destModel])
            errorMessage = App.t "form.error.drag_contains"
            error.text "(#{errorMessage})"
            return false

        # Если перемещается в тот же каталог
        switch data.hitMode
          when 'over'
            if node is data.otherNode.parent
              errorMessage = App.t "form.error.drag_already", context: destModel.type
              error.text "(#{errorMessage})"
              return false
          when 'before', 'after'
            if node.getParent() is data.otherNode.parent
              errorMessage = App.t "form.error.drag_already", context: destModel.type
              error.text "(#{errorMessage})"
              return false

        # Проверяем количество уровней потомков
        levels = []
        level  = data.otherNode.visit (node) -> levels.push node.getLevel()
        level  = if levels.length then _.max levels else 0

        # Суммарный уровень уровней
        level = node.getLevel() + level - data.otherNode.getLevel() + 1

        if level > 7 # если превышает допустимый уровень вложенности, запрещаем
          errorMessage = App.t "form.error.drag_limit"
          error.text "(#{errorMessage})"
          return false

        data.ui.helper.data("mode", true)
        true

      dragDrop: (node, data) =>
        return false unless data.ui.helper.data("mode")

        switch data.hitMode
          when 'over'
            parent = data.node
          when 'before', 'after'
            parent = data.node.getParent()

        if @view.tree.rootNode is parent
          parent = null

        if data.otherNode is null
          data.ui.helper.dropTarget = parent
          return true
        else
          collection.trigger 'move', data.otherNode, parent


class App.Behaviors.Grid.Drag extends Marionette.Behavior

  dragElements: ->
    return unless @config.draggable

    models = @getSelectedModels()
    return unless models.length

    $ '.slick-row.ui-draggable', @grid.getCanvasNode()
    .draggable 'destroy'

    o =
      appendTo: "body"
      cursorAt:
        top  : -12
        left : -20
      connectToFancytree: true
      start: (e, ui) =>
        ui.helper.currentCategory = @collection.section
        ui.helper.append Marionette.Renderer.render "controls/drag_error"
        true

      stop: (e, ui) =>
        # Если тащили в корень дерева, то заполняем dropTarget, т.к. дерево в этом
        # случае не обрабатывает drop
        if not ui.helper.dropTarget and $(e.toElement).hasClass('ui-fancytree')
          ui.helper.dropTarget = null
        @collection.trigger 'move', ui, models

      revert: -> $.ui.ddmanager?.current?.helper?.hasClass "drop-denied"

      helper: (e) =>
        $ Marionette.Renderer.render "controls/drag",
          count : models.length
          type  : @type

    _.extend o, @config.draggable if _.isObject @config.draggable
    @getSelectedRows().draggable o

  move: (ui, selected) ->
    dt = ui.helper.dropTarget
    return if _.isUndefined dt
    return if ui.helper.hasClass "drop-denied"

    section = @view.collection.section
    dest  = section.collection.get dt.key if dt?.key
    dest  = section.collection.getRootModel() unless dest

    return unless dest
    type  = @type
    sectionType = section.type or App.entry.getConfig(section)?.type

    count = selected.length
    action = "move"

    module = App.currentModule?.moduleName
    return unless module

    # TODO: порефакторить, сделать единый способ наследования классов
    moveClassName = App.Views[module]?[helpers.camelCase(@type, true) + _.capitalize(action)]
    moveClassName = moveClassName ? App.Views.Controls.DialogGridMove

    copyClassName = App.Views[module]?[helpers.camelCase(@type, true) + 'Copy']
    copyClassName = copyClassName ? App.Views.Controls.DialogGridCopy

    # TODO: реализовать с помощью хелпера
    modal = if App.modal2.currentView then App.modal2 else App.modal

    App.modal.show new moveClassName
      type     : type
      selected : selected
      section  : section
      dest     : dest
      action   : 'move_or_copy'
      callback: (data, method) ->
        arr =
          skip: 0
          copy: 0

        async.eachSeries selected
        , (model, callback) =>
          @disableButton true
          return if model[method] dest, callback

          return callback() if arr.skip
          return model[method] dest, callback if arr.copy

          checkbox = if _.indexOf(selected, model) is selected.length - 1 then false else true
          App.modal.show new copyClassName
            type     : type
            section  : section
            model    : model
            action   : 'copy'
            checkbox : checkbox

            callback :  (data, type) ->
              @disableButton true
              arr[type] = data
              return model[type] dest, callback if model[type]
              callback()

        , (err) ->
          if err
            App.Notifier.showError
              title : App.t("select_dialog.#{type}")
              text  : err
              hide  : true
          modal.empty()

  onRender: ->
    c = @view.collection
    f = _.bind @dragElements, @view
    @type = @view.type

    @listenTo c, "move", @move
    @listenTo c, "change", f

    @listenTo @view, "table:column_reorder", f
    @listenTo @view, "table:select", f
