"use strict"

EmptyView             = require 'views/crawler/empty.coffee'
TasksView             = require 'views/crawler/tasks.coffee'
TaskEditForm          = require 'views/crawler/tasks/task.coffee'
ScannerEditForm       = require 'views/crawler/tasks/scanner.coffee'
TaskInfo              = require 'views/crawler/tasks/task_info.coffee'
MissingScannersView   = require 'views/crawler/no_scanner.coffee'

Scanners              = require 'models/crawler/scanner.coffee'
Tasks                 = require 'models/crawler/task.coffee'

App.module "Crawler",
  startWithParent: false

  define: (Module, App) ->

    class Controller extends Marionette.Controller

      _initListener: ->
        @listener = new PushStream
          host          : App.Config.server.replace /(http:\/\/|https:\/\/)/, ""
          modes         : "websocket"
          useSSL        : true
          urlPrefixWebsocket : "/api/notify/listen"

        @listener.addChannel "service_crawler"
        @listener.connect()
        @listener.wrapper.connection.onmessage = (e) =>
          obj = JSON.parse(
            e.data
          ).data

          if obj.type_name.toLowerCase().indexOf('scanner') isnt -1
            @scanners.trigger obj.type_name, obj.guid, obj.data

          if obj.type_name.toLowerCase().indexOf('task') isnt -1
            @crawler_tasks.trigger obj.type_name, obj.guid, obj.data

      _destroyListener: ->
        @listener.disconnect()

      index: ->
        #TODO: Добавить обработку когда нет прав

        @scanners = new Scanners.Collection

        @scanners.fetch()
        .done =>

          unless @scanners.length
            @_noScanners()

            return

          @crawler_tasks = new Tasks.Collection [],
            scanner: @scanners.at(0)

          @tasksView     = new TasksView
            collection: @crawler_tasks

          @tasksView.on 'purgeHashes', =>
            selected = @tasksView.getSelected()

            if selected.length
              for task in selected
                task.purgeHashes()

          @tasksView.on 'editScanner', ({collection, model, view}) =>
            scanner = collection.scanner

            scanner.lock()
            .done =>
              scannerEditForm = new ScannerEditForm
                model: scanner
                title: App.t 'crawler.scanner_edit_configuration'
                cancel: =>
                  @_showEmpty()

                  scanner.unlock()
                done: (data) =>
                  scanner.save data,
                    wait: true
                    success: =>
                      @_showEmpty()

                      scanner.unlock()
                    error: (jqXHR, textStatus, errorThrown) ->
                      scanner.unlock()

                      App.Notifier.showError
                        title : App.t 'menu.crawler'
                        text  : App.t 'crawler.scanner_edit_error'
                        hide  : true

              App.Layouts.Application.content.show scannerEditForm
            .fail (jqXHR, textStatus, errorThrown) ->
              if jqXHR.responseJSON.locked
                error = App.t "crawler.scanner_locked",
                  name: scanner.get 'name'
              else
                error = textStatus

              App.Notifier.showError
                title : App.t 'menu.crawler'
                text  : error
                hide  : true

          # Если выбрали задачу
          @tasksView.on 'task:selected', (task) =>
            #TODO: Попросить Бориса присылать мне все сразу
            $.when(task.status.fetch(), task.sessions.fetch()).always =>
              @_showTaskView(task)

          @tasksView.on 'runTask', =>
            selected = @tasksView.getSelected()

            if selected and selected.length
              for task in selected
                task.start()
                .fail ->
                  App.Notifier.showError
                    title: App.t 'menu.crawler'
                    text:  App.t 'crawler.start_task_error',
                      name: task.get 'name'

          @tasksView.on 'stopTask', =>
            selected = @tasksView.getSelected()

            if selected and selected.length
              for task in selected
                task.stop()
                .fail ->
                  App.Notifier.showError
                    title: App.t 'menu.crawler'
                    text:  App.t 'crawler.start_task_error',
                      task.get 'name'

          @tasksView.on 'createTask', =>
            task = new @crawler_tasks.model
              crawlerId: @scanners.at(0).id
            task.collection = @crawler_tasks

            taskEditForm = new TaskEditForm
              model: task
              title: App.t 'crawler.creating_job'
              cancel: =>
                if @crawler_tasks.length
                  @_showTaskView(@crawler_tasks.at(0))
                else
                  @_showEmpty()
              done: (data) =>
                task.save data,
                  wait: true
                  success: =>
                    @crawler_tasks.add task
                    @_showTaskView(task)
                  error: ->
                    App.Notifier.showError
                      title: App.t 'menu.crawler'
                      text:  App.t 'crawler.create_task_error'

            App.Layouts.Application.content.show taskEditForm

          @tasksView.on 'deleteTask', =>
            selected = @tasksView.getSelected()

            if selected.length

              App.Helpers.confirm
                title: App.t 'crawler.task_delete_dialog_title'
                data: App.t 'crawler.task_delete_dialog_question',
                  tasks: (_.map selected, (task) -> task.get('name')).join(', ')
                accept: =>
                  for task in selected
                    task.destroy()

                  if @crawler_tasks.length
                    @_showTaskView(@crawler_tasks.at(0))
                  else
                    @_showEmpty()

          @tasksView.on 'editTask', =>
            selected = @tasksView.getSelected()

            if selected and selected.length is 1
              selected[0].lock()
              .done =>
                taskEditForm = new TaskEditForm
                  model: selected[0]
                  title: App.t 'crawler.editing_job'
                  cancel: =>
                    selected[0].unlock()
                    @_showTaskView(selected[0])
                  done: (data) =>
                    selected[0].save data,
                      wait: true
                      success: =>
                        selected[0].unlock()
                        @_showTaskView(selected[0])
                      error: ->
                        App.Notifier.showError
                          title: App.t 'menu.crawler'
                          text:  App.t 'crawler.edit_task_error',
                            name: selected[0].get 'name'

                App.Layouts.Application.content.show taskEditForm

          App.Layouts.Application.sidebar.show @tasksView
          @_showEmpty()

          @crawler_tasks.fetch()

        .fail =>

          @_noScanners()

      # PRIVATE
      #
      _noScanners: ->
        $(App.Layouts.Application.sidebar.el).closest('.sidebar').hide()
        App.Layouts.Application.content.show new MissingScannersView

      _showTaskView: (task) ->
        taskView = new TaskInfo
          model: task

        App.Layouts.Application.content.show taskView

        @tasksView.select task

      _showEmpty: ->
        emptyView = new EmptyView
        App.Layouts.Application.content.show emptyView

      _unlockAllEntities: ->
        if App.Controllers.Crawler.scanners
          for scanner in App.Controllers.Crawler.scanners.models
            scanner.unlock()

          if App.Controllers.Crawler.crawler_tasks
            for task in App.Controllers.Crawler.crawler_tasks.models
              task.unlock()

    Module.addInitializer ->
      App.Controllers.Crawler = new Controller
      App.Controllers.Crawler._initListener()

      $(window).on "beforeunload.crawler_unlock", ->
        App.Controllers.Crawler._unlockAllEntities()

        undefined


    Module.addFinalizer ->
      App.Controllers.Crawler._destroyListener()
      App.Controllers.Crawler._unlockAllEntities()
      App.Controllers.Crawler.destroy()
      delete App.Controllers.Crawler

      $(window).off "beforeunload.crawler_unlock"
