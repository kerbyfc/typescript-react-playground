"use strict"

helpers                 = require "common/helpers.coffee"
Event                   = require "models/events/events.coffee"
EventsContentView       = require "views/events/content.coffee"
EventDetailsView        = require("views/events/event.coffee").EventDetails
EmptyEventDetailsView   = require("views/events/event.coffee").EmptyEventDetails

Selection               = require "models/events/selections.coffee"
Tags                    = require "models/lists/tags.coffee"
SelectElementsDialog    = require "views/events/dialogs/select_elements.coffee"
ExportObjectsDialog     = require "views/events/dialogs/export_objects.coffee"
QueryCondition          = require "views/events/selection_create.coffee"

App.module "Events",
  startWithParent: false
  define: (Events, App, Backbone, Marionette, $) ->

    class EventsController extends Marionette.Controller

      parseQuery: (queryString, eventsCollection) ->
        filter = eventsCollection.query.filter

        filter['OBJECT_ID'] = queryString.OBJECT_ID.split(',') if queryString.OBJECT_ID

        filter['RULE_GROUP_TYPE'] = queryString.RULE_GROUP_TYPE.split(',') if queryString.RULE_GROUP_TYPE

        if queryString.SENDERS
          switch queryString.SENDERS_TYPE
            when 'person'
              filter['senders.PARTICIPANT_ID'] = queryString.SENDERS.split(',')
            when 'key'
              filter['senders.KEY'] = queryString.SENDERS.split(',')

        filter['categories.CATEGORY_ID'] = queryString.CATEGORIES.split(',') if queryString.CATEGORIES
        filter['protected_documents.PROT_DOCUMENT_ID'] = queryString.PROTECTED_DOCUMENTS.split(',') if queryString.PROTECTED_DOCUMENTS
        filter['protected_documents.PROT_CATALOG_ID'] = queryString.PROTECTED_CATALOGS.split(',') if queryString.PROTECTED_CATALOGS
        filter['WIDGET_ID'] = queryString.WIDGET.split(',') if queryString.WIDGET

        filter['policies.POLICY_ID'] = queryString.POLICIES.split(',') if queryString.POLICIES

        filter['VIOLATION_LEVEL'] = queryString.VIOLATION_LEVEL.split(',') if queryString.VIOLATION_LEVEL

        # Если указан интервал для событий
        filter['FROM'] = queryString.FROM if queryString.FROM
        filter['TO'] = queryString.TO if queryString.TO

        # Если указали конкретный запрос
        filter['QUERY_ID'] = queryString.QUERY if queryString.QUERY

      executeSelection: (selection, eventsView) ->
        # Ищем запрос в списке запущенных
        if not (selection.get('QUERY_ID') of App.EventsConditionsManager.Events)

          # если не нашли добавляем в очередь и обновляем toolbar
          App.EventsConditionsManager.Events[selection.get('QUERY_ID')] =
            delayed: 0
            started: 0
            timer: null

          eventsView.update_selection_toolbar()

          selection.execute().done ->
            eventsView.update_objects_toolbar()

            App.EventsConditionsManager.Events[selection.get('QUERY_ID')].started = 1

            # Если после запуска запроса в течении 5 секунд он не выполнился
            # уведомляем пользователя что запрос выполняется
            App.EventsConditionsManager.Events[selection.get('QUERY_ID')].timer = _.delay ->
              if (selection.get('QUERY_ID') of App.EventsConditionsManager.Events)
                App.EventsConditionsManager.Events[selection.get('QUERY_ID')].delayed = 1

                App.Notifier.showSuccess({
                  title: App.t('events.conditions.selection'),
                  text: App.t 'events.selection.selection_add_to_query',
                    name: selection.get('DISPLAY_NAME')
                  hide: true
                })
            , 5000
          .fail (resp) ->
            response = resp.responseText

            if response.indexOf("GearmanException") isnt -1
              App.Notifier.showError({
                title: App.t 'events.conditions.selection'
                text: App.t 'events.conditions.selection_gearman_execute_error'
                hide: true
              })
            else if response is "Empty visibility areas for current user"
              App.Notifier.showError({
                title: App.t 'events.conditions.selection'
                text: App.t 'events.conditions.selection_empty_visibility_area_execute_error'
                hide: true
              })
            else
              App.Notifier.showError({
                title: App.t 'events.conditions.selection'
                text: App.t 'events.conditions.selection_execute_error'
                hide: true
              })

            if (selection.get('QUERY_ID') of App.EventsConditionsManager.Events)
              delete App.EventsConditionsManager.Events[selection.get('QUERY_ID')]

              eventsView.update_objects_toolbar()
              eventsView.update_selection_toolbar()
        else
          throw new Error "Запрос #{selection.get('DISPLAY_NAME')} уже выполняется"

      showEvents: (view, query, eventsCollection, selections_collection) ->
        view.blockToolbar()

        eventsCollection.currentPage = 0

        filter = {}

        if query
          selections_collection.fetchOne query.id, {}, (query) ->
            eventsCollection.selection = query
            eventsCollection.sortRule = sort: query.get('QUERY').sort

            filter =
              QUERY_ID: query.id

            eventsCollection.query.filter = filter

            eventsCollection.fetch
              reset: true
              success: ->
                if (query.id of App.EventsConditionsManager.Events)
                  delete App.EventsConditionsManager.Events[query.id]
        else
          eventsCollection.total_count = 0
          eventsCollection.reset([])

      _editCreateCallback: (options, isCancelled, data, execute) ->
        mode = options.model.getMode()

        if not isCancelled
          options.model.saveCondition(data, wait: true)
          .done =>
            options.view.setQuery(options.model)

            if options.action is 'create'
              options.collection.add options.model

            App.Controllers.Events.selectedQuery = options.model.get "QUERY_ID"

            App.modal.empty() if mode is 'advanced'
            App.Layouts.Application.sidebar.show new EmptyEventDetailsView()

            if execute
              @executeSelection(options.model, options.view)
            else
              options.view.update_selection_toolbar()

          .fail (model, response, options) ->

            fields = response.responseJSON
            text   = response.responseText

            if 'DISPLAY_NAME' of fields
              error = App.t 'events.selection.selection_contstraint_violation_error'
            else if text.indexOf 'Empty visibility areas for current user' isnt -1
              error = App.t 'events.conditions.selection_empty_visibility_area_execute_error'
            else
              error = App.t 'events.selection.selection_undefined_error'

            if mode is 'advanced'
              App.modal.currentView.showErrorHint('display_name', error)
            else
              App.Layouts.Application.sidebar.currentView.showErrorHint('display_name', error)
        else
          options.model.fetch()
          App.Layouts.Application.sidebar.show new EmptyEventDetailsView()

      _showConditionBuilder: (mode, model, eventsView, selections_collection) ->
        App.Layouts.Application.sidebar.show new EmptyEventDetailsView()

        if mode is 'lite'
          App.Layouts.Application.sidebar.show new QueryCondition
            model: model
            mode: mode
            callback: _.bind @_editCreateCallback, @,
              action      : 'edit'
              model       : model
              view        : eventsView
              collection  : selections_collection
            extendedClasses: 'sidebar__content'
        else
          App.modal.show new QueryCondition
            title: App.t 'events.conditions.advanced'
            model: model
            mode: mode
            callback: _.bind @_editCreateCallback, @,
              action      : 'edit'
              model       : model
              view        : eventsView
              collection  : selections_collection

      switchToAdvanced: (model, eventsView, selections_collection) ->
        App.Helpers.confirm
          title: App.t 'events.conditions.condition_switch_to_advanced_dialog_title'
          data: App.t 'events.conditions.condition_switch_to_advanced_dialog_question'
          accept: =>
            model.setMode 'advanced'

            @_showConditionBuilder('advanced', model, eventsView, selections_collection)

      initialize: ->
        query = decodeURIComponent(location.href)

        # Парсим url
        queryString = {}
        query.replace(
          new RegExp("([^?=&]+)(=([^&]*))?", "g"), ($0, $1, $2, $3) ->
            queryString[$1] = $3
        )

        delete queryString[location.href.split('?')[0]]

        # Создаем коллекции запросов и событий
        selections_collection = new Selection.collection [], params:
          filter:
            QUERY_TYPE: "query"

        eventsCollection = new Event.Collection()

        eventsView = new EventsContentView
          selections_collection: selections_collection
          eventsCollection: eventsCollection

        eventsCollection.query = {}
        eventsCollection.query.filter = {}

        # По умолчанию сортируем по дате перехвата
        eventsCollection.sortRule = sort:
          CAPTURE_DATE: 'desc'

        @listenTo eventsView, 'query:select', (query) =>
          App.Layouts.Application.sidebar.show new EmptyEventDetailsView

          if query
            App.Controllers.Events["selectedQuery"] = query.id

            eventsCollection.selection = selections_collection.get query.id

            @showEvents(eventsView, query, eventsCollection, selections_collection)

        @listenTo eventsView, 'query:unset', =>
          App.Layouts.Application.sidebar.show new EmptyEventDetailsView

          App.Controllers.Events["selectedQuery"] = null

          eventsCollection.selection = null

          @showEvents(eventsView, null, eventsCollection, selections_collection)

        @listenTo eventsView, 'execute_query', ->
          return if helpers.islock { type: 'query', action: 'show' }

          query = eventsView.getSelectedQuery()

          if query
            App.Layouts.Application.sidebar.show new EmptyEventDetailsView()

            selections_collection.fetchOne query.id, {}, (query) =>
              @executeSelection(query, eventsView)

        @listenTo eventsView, 'edit_query', =>
          return if helpers.islock { type: 'query', action: 'edit' }

          query = eventsView.getSelectedQuery()
          model = selections_collection.get(query.id)

          if query
            @_showConditionBuilder(model.getMode(), model, eventsView, selections_collection)

            App.Layouts.Application.sidebar.currentView.on 'switchToAdvanced', =>
              @switchToAdvanced(model, eventsView, selections_collection)

        @listenTo eventsView, 'copy_query', (mode) ->
          return if helpers.islock { type: 'query', action: 'edit' }

          query = eventsView.getSelectedQuery()

          if query
            model = selections_collection.get(query.id)

            App.Helpers.confirm
              title: App.t 'events.conditions.condition_copy_dialog_title'
              data: App.t 'events.conditions.condition_copy_dialog_question',
                name: query.text
              accept: ->
                copiedQuery = model.copy()
                copiedQuery.saveCondition({copy: true}, wait: true)
                .done ->
                  eventsView.setQuery(copiedQuery)

                  selections_collection.add copiedQuery

                .fail (model, response, options) ->
                  App.Notifier.showError
                    title: App.t 'events.conditions.selection'
                    text: App.t 'events.conditions.condition_copy_error'
                    hide: true

        @listenTo eventsView, 'add_query', (mode) =>
          return if helpers.islock { type: 'query', action: 'edit' }

          model = new selections_collection.model
            mode: mode
            condition:
              "link_operator":"and"
              "children":[
                "category":"capture_date"
                "value":
                    "type":"this_week"
              ]

          @_showConditionBuilder(mode, model, eventsView, selections_collection)

          App.Layouts.Application.sidebar.currentView.on 'switchToAdvanced', =>
            @switchToAdvanced(model, eventsView, selections_collection)

        @listenTo eventsView, 'delete_query', =>
          return if helpers.islock { type: 'query', action: 'delete' }

          query = eventsView.getSelectedQuery()

          if query
            App.Helpers.confirm
              title: App.t 'events.conditions.condition_delete_dialog_title'
              data: App.t 'events.conditions.condition_delete_dialog_question',
                name: query.text
              accept: =>
                selections_collection.get(query.id).destroy
                  success: =>
                    @showEvents(eventsView, null, eventsCollection, selections_collection)

                    App.Layouts.Application.sidebar.show new EmptyEventDetailsView()
                  error: ->
                    App.Notifier.showError({
                      title: App.t 'events.conditions.selection'
                      # TODO: Добавить локализацию
                      text: "Не удалось удалить запрос #{query.text}"
                      hide: true
                    })

        @listenTo eventsView, 'export', (options) ->
          return if helpers.islock { type: 'event', action: 'export' }

          query = eventsView.getSelectedQuery()

          if query

            App.modal.show new ExportObjectsDialog
              title: App.t 'events.events.export'
              selected: eventsView.currentView.getSelected()
              callback: (data) ->
                opt =
                  format: data.format
                  query: query.id
                  type: data.type

                if data.scope isnt 'all'
                  opt.scope = _.map eventsView.currentView.getSelected(), (event) -> event.id
                else
                  opt.scope = "all"

                App.modal.empty()

                options.view.currentView.collection.exportEvents(opt)
                .done ->
                  App.Notifier.showSuccess
                    title: App.t 'events.events.export'
                    text: App.t 'events.events.export_run',
                      selection: query.text
                .fail ->
                  App.Notifier.showError
                    title: App.t 'events.events.export'
                    text: App.t 'events.events.export_fail',
                      selection: query.text

        @listenTo eventsView, 'setTags', ->
          return if helpers.islock { type: 'event', action: 'edit_tag' }

          selected = eventsView.currentView.getSelected()

          return if selected.length is 0

          # Получаем выбранные объекты
          objects = _.union [], selected
          tags_ = []

          # Собираем теги с выделенных объектов
          _.each objects, (object) ->
            tags_ = _.union tags_, _.pluck object.get('tags'), 'TAG_ID'

          App.modal.show new SelectElementsDialog
            title: App.t 'events.events.set_tag'
            selected: tags_
            collection: new Tags.Collection()
            table_config:
              default:
                checkbox: true
                sortCol: "DISPLAY_NAME"
              columns: [
                id      : "COLOR"
                name    : ""
                field   : "COLOR"
                width   : 40
                resizable : false
                sortable  : true
                cssClass  : "center"
                formatter : (row, cell, value, columnDef, dataContext) ->
                  "<div class='tag__color' data-color='#{dataContext.get('COLOR')}'></div>"
              ,
                id      : "DISPLAY_NAME"
                name    : App.t 'lists.tags.display_name'
                field   : "DISPLAY_NAME"
                resizable : true
                sortable  : true
                minWidth  : 150
              ,
                id      : "NOTE"
                name    : App.t 'lists.tags.note'
                resizable : true
                sortable  : true
                minWidth  : 150
                field   : "NOTE"
              ]
            callback: (added_tags, removed_tags) ->
              if added_tags.length
                _.each objects, (object) ->
                  object.setTags(added_tags)
                  .done ->
                    if objects.length is 1
                      eventsView.trigger 'event:selected', objects[0], true
                  .fail (data, textStatus, jqXHR) ->
                    App.Notifier.showError({
                      title: App.t 'events.conditions.selection'
                      # TODO: Добавить локализацию
                      text: "Не удалось добавить теги для обьекта #{model.id}: #{textStatus}"
                      hide: true
                    })

              # удаляем теги
              if removed_tags.length
                _.each objects, (object) ->
                  object.deleteTags(removed_tags)
                  .done ->
                    if objects.length is 1
                      eventsView.trigger 'event:selected', objects[0], true
                  .fail (data, textStatus, jqXHR) ->
                    App.Notifier.showError({
                      title: App.t 'events.conditions.selection'
                      # TODO: Добавить локализацию
                      text: "Не удалось удалить теги для обьекта #{model.id}: #{textStatus}"
                      hide: true
                    })

        @listenTo eventsView, 'setDecision', (decision) ->
          return if helpers.islock { type: 'event', action: 'edit_user_decision' }

          selected = eventsView.currentView.getSelected()

          return if selected.length is 0

          objects = _.union [], selected

          _.each objects, (obj) ->
            obj.save
              "DATA":
                "DECISION": decision
              "ACTION": "set_decision"
            ,
              patch: true
              wait: true
              success: (model, response, options) ->
                if objects.length is 1
                  eventsView.trigger 'event:selected', objects[0]
              error: (model, xhr, options) ->
                App.Notifier.showError({
                  title: App.t 'events.conditions.selection'
                  # TODO: Добавить локализацию
                  text: "Не удалось изменить решение пользователя для обьекта #{model.id}"
                  hide: true
                })

        @listenTo eventsView, 'downloadObject', ->
          selected = eventsView.currentView.getSelected()

          return if selected.length is 0

          objects = _.union [], selected

          url = "#{App.Config.server}/api/object/export?"

          _.each objects, (obj) ->
            url += "object_id[]=#{obj.id}&"

          window.location = url.substring(0, url.length - 1)

        @listenTo eventsView, 'delete-tag', (model, tags) ->
          return if helpers.islock { type: 'event', action: 'edit_tag' }

          model.save
            "DATA":
              "TAGS": tags
            "ACTION": "remove_tags"
          ,
            patch: true
            wait: true
            success: ->
              eventsView.trigger 'event:selected', model, true
            error: (model, xhr, options) ->
              App.Notifier.showError({
                title: App.t 'events.conditions.selection'
                # TODO: Добавить локализацию
                text: "Не удалось удалить тег для обьекта #{model.id}"
                hide: true
              })

        @listenTo eventsView, 'event:selected', (model, force = false) ->
          current_model = App.Layouts.Application.sidebar.currentView.model
          return if current_model is model and not force

          $.xhrPool.abortAll()

          eventDetails          = new EventDetailsView()
          eventDetails.model    = model
          eventDetails.status   = 'loading'
          App.Layouts.Application.sidebar.show eventDetails

          model.loadContent()
          .done ->
            eventsView.update_objects_toolbar(model)

            eventDetails.status   = 'loaded'
            eventDetails.showInfo()
          .fail (object) ->
            if object.statusText isnt "abort"
              App.Notifier.showError({
                title: App.t 'events.conditions.selection'
                # TODO: Добавить локализацию
                text: "Не удалось загрузить данные для обьекта #{model.id}"
                hide: true
              })

        @listenTo @, 'selection:failed', (message) ->
          clearTimeout App.EventsConditionsManager.Events[message.data.data.QUERY_ID].timer
          delete App.EventsConditionsManager.Events[message.data.data.QUERY_ID]

          if message.data.data.error
            error = message.data.data.error
          else
            if message.data.message
              if $.i18n.exists "events.events.#{message.data.message}"
                error = App.t "events.events.#{message.data.message}"
              else
                error = message.data.message

          App.Notifier.showError
            title: App.t 'events.conditions.selection'
            text: App.t 'events.conditions.selection_error',
              name: message.data.data.DISPLAY_NAME
              error: error
            hide: message.data.show isnt 'sticky'

          eventsView.update_selection_toolbar()

        @listenTo @, 'selection:done', (query_id) =>
          # Сбрасываем таймер для запроса
          clearTimeout App.EventsConditionsManager.Events[query_id].timer
          delete App.EventsConditionsManager.Events[query_id]

          @showEvents(eventsView, {id: query_id}, eventsCollection, selections_collection)

          eventsView.update_selection_toolbar()

        App.Layouts.Application.sidebar.show new EmptyEventDetailsView()
        App.Layouts.Application.content.show eventsView,
          maxWidth: $(window).width() / 1.8
          width: $(window).width() / 1.8

        if not _.isEmpty(queryString)
          @parseQuery(queryString, eventsCollection)

          eventsCollection.fetch
            reset: true
            success: ->
              if queryId = queryString.QUERY
                eventsView.updateQueryCompleteDate queryId
        else
          @showEvents(eventsView, null, eventsCollection, selections_collection)

    # Initializers And Finalizers
    # ---------------------------
    Events.addInitializer ->
      App.Controllers.Events = new EventsController()

      App.vent.trigger 'main:layout:sidebar:position', 'right'

    Events.addFinalizer ->
      App.Controllers.Events = null

      App.vent.trigger 'main:layout:sidebar:position', 'left'
