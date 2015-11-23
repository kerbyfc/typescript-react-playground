"use strict"

async                   = require "async"

helpers                 = require "common/helpers.coffee"

Tag                     = require "models/lists/tags.coffee"
TagsView                = require "views/lists/tags.coffee"
TagDialog               = require "views/lists/dialogs/tag.coffee"

Statuses                = require "models/lists/statuses.coffee"
StatusesView            = require "views/lists/statuses.coffee"
StatusDialog            = require "views/lists/dialogs/status.coffee"

Resources               = require "models/lists/resources.coffee"
ResourceGroups          = require "models/lists/resourceGroups.coffee"
ResourceListItemsView   = require "views/lists/resource_list_items.coffee"
ResourceGroupsView      = require "views/lists/resource_lists.coffee"
ResourceGroupDialog     = require "views/lists/dialogs/resource_list.coffee"
ResourceListItemDialog  = require "views/lists/dialogs/resource_list_item.coffee"

Perimeters              = require "models/lists/perimeters.coffee"
PerimeterListsView      = require "views/lists/perimeters.coffee"
PerimeterListDialog     = require "views/lists/dialogs/perimeter_list.coffee"
PerimeterView           = require "views/lists/perimeter.coffee"


App.module "Lists",
  startWithParent: false
  define: (Lists, App, Backbone, Marionette, $) ->

    class ListsController extends Marionette.Controller

      events:
        resources:
          'create'    : (options) ->
            return if helpers.islock { type: 'resource', action: 'edit' }
            model = new options.collection.model()

            App.modal.show new ResourceListItemDialog
              title: App.t 'lists.resources.resource_create_dialog_title'
              model: model
              callback: (data) ->
                data.LIST_ID = options.view.options.selected.id

                model.save data,
                  wait: true
                  success: ->
                    App.modal.empty()

                    options.collection.add model

                    options.view.select model

                  error: (model, xhr, options) ->
                    response = $.parseJSON(xhr.responseText)
                    keys = _.keys response

                    for key in keys
                      errors = response[key]

                      switch key
                        when 'VALUE'
                          if 'not_unique_field' in errors
                            error = App.t 'lists.resources.resource_contstraint_violation_error'
                        else
                          error = App.t 'global.undefined_error'

                    App.Notifier.showError
                      title: App.t 'lists.resources_tab'
                      text: error
                      hide: true

          'edit'      : (options) ->
            selected = options.view.getSelectedModels()

            if selected.length is 1
              App.modal.show new ResourceListItemDialog
                title: App.t 'lists.resources.resource_edit_dialog_title'
                model: selected[0]
                callback: (data) ->
                  selected[0].save data,
                    wait: true
                    success: ->
                      App.modal.empty()

                    error: (model, xhr, options) ->
                      response = $.parseJSON(xhr.responseText)
                      keys = _.keys response

                      for key in keys
                        errors = response[key]

                        switch key
                          when 'VALUE'
                            if 'not_unique_field' in errors
                              error = App.t 'lists.resources.resource_contstraint_violation_error'
                          else
                            error = App.t 'global.undefined_error'

                      App.Notifier.showError
                        title: App.t 'lists.resources_tab'
                        text: error
                        hide: true
          'delete'    : (options) ->
            selected = options.view.getSelectedModels()

            return if helpers.islock { type: 'resource', action: 'delete' }

            App.Helpers.confirm
              title: App.t 'lists.resources.resource_delete_dialog_title'
              data: App.t 'lists.resources.resource_delete_dialog_question',
                resources: App.t 'lists.resources.resource', {count: selected.length}
              accept: ->
                for model in selected
                  model.destroy
                    data: JSON.stringify(model.toJSON())
                    wait: true
                    success: ->
                      options.view.clearSelection()
                    error: (model, xhr, options) ->
                      #ToDO: Добавить обработку ошибок
                      throw new Error(xhr.responseText)

          'edit:inline' : (item, field, value, callback) ->
            data = {}
            data[field] = value

            item.save data,
              wait: true
              error: (model, xhr) ->
                response = $.parseJSON(xhr.responseText)
                keys = _.keys response

                for key in keys
                  errors = response[key]

                  switch key
                    when 'VALUE'
                      if 'not_unique_field' in errors
                        err = App.t 'lists.resources.resource_contstraint_violation_error'
                    else
                      err = App.t 'global.undefined_error'

                callback(err)

      resources: (id) ->
        resources_collection = new ResourceGroups.TreeCollection
        resource_items_collection = new Resources.Collection

        contentView = new ResourceGroupsView.ResourceLists
          collection: resources_collection
          selected: id

        @listenTo App.Configuration, "configuration:rollback", ->
          resources_collection.fetch
            reset: true
            wait: true

        # Создание группы ресурсов
        @listenTo contentView, 'create', ->
          model = new resources_collection.model()

          App.modal.show new ResourceGroupDialog
            title: App.t 'lists.resources.resource_list_create_dialog_title'
            model: model
            callback: (data) ->
              data.LIST_TYPE = 'web_type'

              model.save data,
                wait: true
                success: ->
                  App.modal.empty()

                  resources_collection.add model

                error: (model, xhr, options) ->
                  response = $.parseJSON(xhr.responseText)

                  keys = _.keys response

                  for key in keys
                    errors = response[key]

                    switch key
                      when "DISPLAY_NAME"
                        if 'not_unique_field' in errors
                          error = App.t 'lists.resources.resource_list_contstraint_violation_error'
                      else
                        error = App.t 'global.undefined_error'

                  App.Notifier.showError
                    title: App.t 'lists.resources_tab'
                    text: error

        # Редактирование группы ресурсов
        @listenTo contentView, 'edit', ->
          model = resources_collection.get contentView.getActiveNode()?.key

          if model
            App.modal.show new ResourceGroupDialog
              title: App.t 'lists.resources.resource_list_edit_dialog_title'
              model: model
              callback: (data) ->
                model.save data,
                  wait: true
                  success: ->
                    App.modal.empty()

                  error: (model, xhr, options) ->
                    response = $.parseJSON(xhr.responseText)

                    keys = _.keys response

                    for key in keys
                      errors = response[key]

                      switch key
                        when "DISPLAY_NAME"
                          if 'not_unique_field' in errors
                            error = App.t 'lists.resources.resource_list_contstraint_violation_error'
                        else
                          error = App.t 'global.undefined_error'

                    App.Notifier.showError
                      title: App.t 'lists.resources_tab'
                      text: error

        # Удаление группы ресурсов
        @listenTo contentView, 'delete', ->
          model = resources_collection.get contentView.getActiveNode()?.key

          if model
            App.Helpers.confirm
              title: App.t "lists.resources.resource_list_delete_dialog_title"
              data: App.t "lists.resources.resource_list_delete_dialog_question",
                name: model.get 'DISPLAY_NAME'
              accept: ->
                model.destroy
                  wait: true
                  error: ->
                    # ToDo: Добавить обработку ошибок
                    throw new Error("Can't delete model")

        # Создание политики
        @listenTo contentView, 'create_policy', ->
          selected = resources_collection.get contentView.getActiveNode()?.key

          App.Policy?.createPolicy = [
            ID    : selected.id
            NAME  : selected.getName()
            TYPE  : 'resource'
            content : selected.toJSON()
          ]

          App.Routes.Application.navigate "/policy", trigger: true

        @listenTo contentView, 'select', (group) ->
          if group
            App.Layouts.Application.content.show new ResourceListItemsView
              collection: resource_items_collection
              selected: resources_collection.get group

            Marionette.bindEntityEvents @, App.Layouts.Application.content.currentView, @events.resources

            resource_items_collection.filter = filter:
              LIST_ID: group

            resource_items_collection.currentPage = 0

            resource_items_collection.fetch
              reset: true
          else
            App.Layouts.Application.content.show new ResourceGroupsView.ResourceListsEmpty

        App.Layouts.Application.sidebar.show contentView
        App.Layouts.Application.content.show new ResourceListItemsView
          collection: resource_items_collection

        Marionette.bindEntityEvents @, App.Layouts.Application.content.currentView, @events.resources

        resources_collection.fetch
          reset: true

      ###########################################################################
      # PRIVATE

      ###*
       * Perimeters collection
       * @type {Perimeters.TreeCollection}
      ###
      _perimetersCollection : null

      ###*
       * Perimeters list view for sidebar
       * @type {PerimeterListsView.PerimeterLists}
      ###
      _perimetersListView : null

      ###*
       * Perimeter renderer in case of coccurpted perimeterId or
       * there is no selected perimeter into the list @_perimetersListView
       * @type {PerimeterListsView.PerimeterListsEmpty}
      ###
      _perimitersEmpty : null

      ###*
       * 32 bits perimeter's id
       * @type {String}
      ###
      _perimeterId : null

      _perimeterView : null

      _perimetersInitialized: false

      ###*
       * Start up components for perimeters
       * TODO: check for event binded memory leaks
       * @return {PerimeterListsView.PerimeterLists}
      ###
      _initializePerimeters: (callback) =>

        @_perimetersEmpty       = new PerimeterListsView.PerimeterListsEmpty
        @_perimetersCollection  = new Perimeters.TreeCollection
        @_perimetersListView    = new PerimeterListsView.PerimeterLists
          collection: @_perimetersCollection

        @listenTo App.Configuration, "configuration:rollback", =>
          @_perimetersCollection.fetch
            reset: true
            wait: true

        parseError = (xhr, data) ->
          response = $.parseJSON(xhr.responseText)
          keys = _.keys response

          for key in keys
            errors = response[key]

            switch key
              when 'DISPLAY_NAME'
                if 'not_unique_field' in errors
                  error = App.t 'lists.perimeters.perimeter_contstraint_violation_error',
                    name: data.DISPLAY_NAME
              else
                error = App.t 'global.undefined_error'
          error

        @listenTo @_perimetersListView, 'create', =>
          model = new @_perimetersCollection.model()

          App.modal.show new PerimeterListDialog
            title: App.t 'lists.perimeters.perimeter_list_create_dialog_title'
            model: model
            callback: (data) =>
              model.save data,
                wait: true
                success: =>
                  App.modal.empty()
                  @_perimetersCollection.add model

                error: (model, xhr, options) ->
                  App.Notifier.showError
                    title: App.t 'lists.perimeters_tab'
                    text: parseError(xhr, data)
                    hide: true

        @listenTo @_perimetersListView, 'edit', =>
          model = @_perimetersCollection.get @_perimetersListView.getActiveNode()?.key

          if model
            App.modal.show new PerimeterListDialog
              title: App.t 'lists.perimeters.perimeter_list_edit_dialog_title'
              model: model
              callback: (data) ->
                model.save data,
                  wait: true
                  success: ->
                    App.modal.empty()

                  error: (model, xhr, options) ->
                    App.Notifier.showError
                      title: App.t 'lists.perimeters_tab'
                      text: parseError(xhr, data)
                      hide: true

        @listenTo @_perimetersListView, 'delete', =>
          model = @_perimetersCollection.get @_perimetersListView.getActiveNode()?.key

          if model
            App.Helpers.confirm
              title: App.t "lists.perimeters.perimeter_list_delete_dialog_title"
              data: App.t "lists.perimeters.perimeter_list_delete_dialog_question",
                name: model.get 'DISPLAY_NAME'
              accept: ->
                model.destroy
                  wait: true
                  error: ->
                    throw new Error("Can't delete model")

        @listenTo @_perimetersListView, 'select', (id) ->
          @_navigateToPerimeter(id)

        @_perimetersCollection.fetch(reset:true).done =>
          @_perimetersInitialized = true
          # invoke perimeters again with saved perimeter's id
          @perimeters(@_perimeterId)

        # if perimeter was deleted
        App.reqres.setHandler 'lists:perimeters:tree:set:active', (id) =>
          @_navigateToPerimeter(id)

        App.Layouts.Application.sidebar.show @_perimetersListView

      _navigateToPerimeter: (id) =>
        if id
          @_perimetersListView.select(@_perimetersCollection.get(id))
          App.vent.trigger 'nav', "lists/perimeters/#{id}"
        else
          @_perimetersListView.select null
          App.vent.trigger 'nav', "lists/perimeters/"
      ###*
       * Set focus to the perimeter with specified id
       * One became selected into _perimetersListView
       * and rendered in content region of App
       * according to perimeter model with current id
       * @param {String} - id of perimeter
       * @return {Boolean}
      ###
      _showPerimeter: =>
        perimeter = @_perimetersCollection.get @_perimeterId
        if perimeter
          App.Layouts.Application.content.show new PerimeterView
            model: perimeter
        else
          App.Layouts.Application.content.show @_perimetersEmpty

      ###*
       * Render perimeters relayted content
       * @param {String} perimeters id, if this argument missed
       # or wrong this module renders perimeters views with no selection
      ###
      perimeters: (id) ->
        @_perimeterId = id

        if @_perimetersInitialized
          if @_perimetersCollection.get @_perimeterId
            @_showPerimeter()
          else
            @_navigateToPerimeter(null)
        else
          @_initializePerimeters()

      statuses: ->
        statuses_collection = new Statuses.Collection

        contentView = new StatusesView
          collection: statuses_collection

        @listenTo contentView, 'sort', _.bind(statuses_collection.sortCollection, statuses_collection)

        @listenTo App.Configuration, "configuration:rollback", ->
          statuses_collection.fetch
            reset: true
            wait: true

        parseError = (xhr, data) ->
          response = $.parseJSON(xhr.responseText)
          keys = _.keys response

          for key in keys
            errors = response[key]

            switch key
              when 'DISPLAY_NAME'
                if 'not_unique_field' in errors
                  error = App.t 'lists.statuses.status_contstraint_violation_error',
                    name: data.DISPLAY_NAME
              else error = App.t 'global.undefined_error'

          return error

        @listenTo contentView, 'create_policy', ->
          return if helpers.islock { type: 'policy_person', action: 'edit' }

          selected = contentView.getSelectedModels()
          return unless selected.length

          App.Policy?.createPolicy = _.map selected, (item) ->
            ID    : item.id
            NAME  : item.getName()
            TYPE  : 'status'
            content : item.toJSON()

          App.Routes.Application.navigate "/policy", {trigger: true}

        @listenTo contentView, 'delete', ->
          selected = contentView.getSelectedModels()

          if selected.length
            App.Helpers.confirm
              title: App.t 'lists.statuses.status_delete_dialog_title'
              data: App.t 'lists.statuses.status_delete_dialog_question',
                statuses: App.t 'lists.statuses.status', {count: selected.length}
              accept: ->
                async.each selected, (model, callback) ->
                  model.destroy
                    wait: true
                    error: (model, response, options) ->
                      #ToDo: Локализовать
                      callback("Can't delete status")
                    success: (model, response, options) ->
                      callback()
                , (err) ->
                  if (err)
                    App.Notifier.showError
                      title: App.t 'lists.statuses_tab'
                      text: err
                      hide: true

                  contentView.clearSelection()

        @listenTo contentView, 'edit', ->
          selected = contentView.getSelectedModels()

          if selected.length is 1
            App.modal.show new StatusDialog
              title: App.t 'lists.statuses.status_edit_dialog_title'
              collection: statuses_collection
              model: selected[0]
              blocked: not helpers.can({type: 'status', action: 'edit'})
              callback: (data) ->
                selected[0].save data,
                  wait: true
                  success: (model, collection, options) ->
                    App.modal.empty()
                  error: (model, xhr, options) ->

                    App.Notifier.showError
                      title: App.t 'lists.statuses_tab'
                      text: parseError(xhr, data)
                      hide: true

        @listenTo contentView, 'create', ->
          model = new statuses_collection.model()

          App.modal.show new StatusDialog
            title: App.t 'lists.statuses.status_create_dialog_title'
            collection: statuses_collection
            model: model
            callback: (data) ->
              model.save data,
                success: (model, collection, options) ->
                  statuses_collection.add model

                  contentView.select model

                  App.modal.empty()
                error: (model, xhr, options) ->

                  App.Notifier.showError
                    title: App.t 'lists.statuses_tab'
                    text: parseError(xhr, data)
                    hide: true

        @listenTo contentView, 'edit:inline', (item, field, value, callback) ->
          data = {}
          data[field] = value
          item.save data,
            wait: true
            error: (model, xhr) ->
              callback(parseError(xhr, data))

        App.Layouts.Application.content.show contentView

        statuses_collection.sortRule =
          'DISPLAY_NAME': 'ASC'

        statuses_collection.fetch
          reset: true
          wait: true

      tags: ->
        tags_collection = new Tag.Collection

        @listenTo App.Configuration, "configuration:rollback", ->
          tags_collection.fetch
            reset: true
            wait: true

        contentView = new TagsView
          collection: tags_collection

        parseError = (xhr, data) ->
          response = $.parseJSON(xhr.responseText)
          keys = _.keys response

          for key in keys
            errors = response[key]

            switch key
              when 'DISPLAY_NAME'
                if 'not_unique_field' in errors
                  error = App.t 'lists.tags.tag_contstraint_violation_error',
                    name: data.DISPLAY_NAME
              else error = App.t 'global.undefined_error'

          return error

        @listenTo contentView, 'sort', _.bind(tags_collection.sortCollection, tags_collection)

        @listenTo contentView, 'delete', ->
          selected = contentView.getSelectedModels()

          if selected.length
            App.Helpers.confirm
              title: App.t 'lists.tags.tag_delete_dialog_title'
              data: App.t 'lists.tags.tag_delete_dialog_question',
                tags: App.t 'lists.tags.tag', {count: selected.length}
              accept: ->
                async.each selected, (model, callback) ->
                  model.destroy
                    wait: true
                    error: (model, response, options) ->
                      #ToDo: Локализовать
                      callback("Can't delete tag")
                    success: (model, response, options) ->
                      callback()
                , (err) ->
                  if (err)
                    App.Notifier.showError
                      title: App.t 'menu.tag'
                      text: err
                      hide: true

                  contentView.clearSelection()

        @listenTo contentView, 'edit', ->
          selected = contentView.getSelectedModels()

          if selected.length is 1
            App.modal.show new TagDialog
              title: App.t 'lists.tags.tag_edit_dialog_title'
              blocked: not helpers.can({type: 'tag', action: 'edit'})
              collection: tags_collection
              model: selected[0]
              callback: (data) ->
                selected[0].save data,
                  wait: true
                  success: (model, collection, options) ->
                    App.modal.empty()
                  error: (model, xhr, options) ->

                    App.Notifier.showError
                      title: App.t 'menu.tag'
                      text: parseError(xhr, data)
                      hide: true

        @listenTo contentView, 'create', ->
          model = new tags_collection.model()

          App.modal.show new TagDialog
            title: App.t 'lists.tags.tag_create_dialog_title'
            collection: tags_collection
            model: model
            callback: (data) ->
              model.save data,
                wait: true,
                success: (model, collection, options) ->
                  tags_collection.add model

                  contentView.select model

                  App.modal.empty()
                error: (model, xhr, options) ->

                  App.Notifier.showError
                    title: App.t 'menu.tag'
                    text: parseError(xhr, data)
                    hide: true

        @listenTo contentView, 'edit:inline', (item, field, value, callback) ->
          data = {}
          data[field] = value

          item.save data,
            wait: true
            error: (model, xhr) ->
              callback(parseError(xhr, data))

        App.Layouts.Application.content.show contentView

        tags_collection.sortRule =
          'DISPLAY_NAME': 'ASC'

        tags_collection.fetch
          reset: true
          wait: true

      destroy: ->
        super()
        App.reqres.removeHandler 'lists:perimeters:set:active', @_setActivePerimeter
        delete @_perimetersCollection
        @_perimetersListView?.destroy()
        @_perimitersEmpty?.destroy()



    # Initializers And Finalizers
    # ---------------------------
    Lists.addInitializer ->
      # Стартуем контроллер конфигурации
      App.Configuration.show()
      App.Controllers.Lists = new ListsController()

    Lists.addFinalizer ->
      App.Controllers.Lists.destroy()
      App.Configuration.hide()
