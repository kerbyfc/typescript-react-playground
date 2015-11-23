"use strict"

async = require "async"

require "models/protected/catalog.coffee"
require "models/protected/document.coffee"

require "views/protected/condition.coffee"
require "views/protected/entry.coffee"
require "views/protected/catalog.coffee"
require "views/protected/document.coffee"

require "views/protected/dialog/catalog.coffee"
require "views/protected/dialog/document.coffee"

require "behaviors/common/form.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    class Controller extends Marionette.Controller

      index: (catalogId, id) ->
        layouts = App.Layouts.Application
        catalogs = new App.Models.Protected.Catalog

        sidebar = new App.Views.Protected.Catalog
          collection       : catalogs
          resize_container : $ App.Layouts.Application.sidebar.el
          filter           : true
          drag             : true
          type             : "catalog"

        collection = new App.Models.Protected.Document

        content = new App.Views.Protected.Document collection: collection

        @listenTo catalogs, "change add remove", ->
          App.Configuration.trigger "configuration:enter_edit_mode"

        @listenTo catalogs, 'select', (section, id) ->
          if collection.section
            collection.stopListening collection.section, "change:ENABLED"

          collection.section = section

          collection.listenTo section, "change:ENABLED", (section) ->
            if section is collection.section
              collection.fetch reset: true

          el = content.$el
          if not section or section.isRoot()
            el.hide()
            collection.reset() if collection.length
            return

          el.show()

          # Сохраняем фильтр по категори в коллекции - нужно для правильной пагинации
          (o = {})["catalog.#{section.idAttribute}"] = section.id
          collection.filterData = filter: o

          if not collection.sortRule
            collection.sortRule = sort: "DISPLAY_NAME": "ASC"

          # Сбрасываем текущую страницу пагинации
          collection.currentPage = 0

          $.xhrPool.abortAll()

          collection.filterData.filter.DOCUMENT_ID = id if id

          collection.fetch reset: true

        App.Configuration.on "configuration:rollback", ->
          sidebar.clearSelection()
          collection.reset()
          catalogs.fetch()

        @listenTo collection, "change add remove", ->
          App.Configuration.trigger "configuration:enter_edit_mode"

        layouts.sidebar.show sidebar
        layouts.content.show content
        content.$el.hide()

        catalogs.fetch
          reset   : true
          wait    : true
          success : ->
            section = catalogs.get catalogId, true
            sidebar.select section, false if catalogId

            catalogs.trigger "select", section, id

    # Initializers And Finalizers
    # ---------------------------
    Module.addInitializer ->
      App.Controllers.Protected = new Controller

      App.Configuration.show()

    Module.addFinalizer ->
      App.Controllers.Protected.destroy()
      delete App.Controllers.Protected
      App.Configuration?.hide()
