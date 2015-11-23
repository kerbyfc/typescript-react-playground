"use strict"

async = require "async"
helpers = require "common/helpers.coffee"

require "models/analysis/category.coffee"
require "models/analysis/term.coffee"
require "models/analysis/fingerprint.coffee"
require "models/analysis/form.coffee"
require "models/analysis/stamp.coffee"
require "models/analysis/text_object.coffee"
require "models/analysis/text_object_pattern.coffee"
require "models/analysis/graphic.coffee"

require "controllers/configuration.coffee"

require "views/analysis/category.coffee"
require "views/analysis/fingerprint.coffee"
require "views/analysis/form.coffee"
require "views/analysis/stamp.coffee"
require "views/analysis/table.coffee"
require "views/analysis/graphic.coffee"
require "views/analysis/term.coffee"
require "views/analysis/text_object.coffee"
require "views/analysis/text_object_pattern.coffee"

require "views/analysis/dialogs/category.coffee"
require "views/analysis/dialogs/text_object.coffee"
require "views/analysis/dialogs/term.coffee"
require "views/analysis/dialogs/text_object_pattern.coffee"
require "views/analysis/dialogs/fingerprint.coffee"
require "views/analysis/dialogs/table.coffee"
require "views/analysis/dialogs/stamp.coffee"
require "views/analysis/dialogs/form.coffee"
require "views/analysis/dialogs/table_condition.coffee"

require "behaviors/common/toolbar.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    class AnalysisController extends Marionette.Controller

      graphic: (type, id) ->

        collection = new App.Models.Analysis.Graphic
        content    = new App.Views.Analysis.Graphic collection: collection

        App.Layouts.Application.content.show content

        $ App.Layouts.Application.sidebar.el
        .closest '.sidebar'
        .hide()

        if id
          collection.fetchOne id, {}, (model) ->
            collection.reset model
        else
          collection.fetch
            reset : true
            wait  : true

      index: (type, categoryId, id) ->
        @stopListening()
        return @[type]? arguments... if @[type]

        layouts = App.Layouts.Application

        categories = new App.Models.Analysis["Group#{helpers.camelCase(type, true)}"] null, type: type

        sidebar = new App.Views.Analysis.Category
          collection       : categories
          resize_container : $ App.Layouts.Application.sidebar.el
          filter           : true
          drag             : true

        collection = new App.Models.Analysis[helpers.camelCase(type, true)]
        content    = new App.Views.Analysis[helpers.camelCase(type, true)]
          collection : collection
          categories : categories

        # Если произошел откат конфигурации, обновляем дерево категорий
        App.Configuration.on "configuration:rollback", ->
          sidebar.clearSelection()
          collection.reset()
          categories.fetch reset: true

        @listenTo categories, "change add remove", ->
          App.Configuration.trigger "configuration:enter_edit_mode"

        idAttribute = collection.model::idAttribute

        @listenTo categories, 'select', (section, id) ->
          collection.section = section

          el = content.$el
          if not section or section.isRoot()
            el.hide()
            collection.reset() if collection.length
            return

          el.show()

          # Сохраняем фильтр по категори в коллекции - нужно для правильной пагинации
          (o = {})["category.#{section.idAttribute}"] = section.id
          collection.filterData = filter: o

          if not collection.sortRule
            collection.sortRule = sort: "DISPLAY_NAME": "ASC"

          # Сбрасываем текущую страницу пагинации
          collection.currentPage = 0

          $.xhrPool.abortAll()

          collection.trigger 'search:clear'

          collection.filterData.filter[idAttribute] = id if id
          collection.fetch reset: true

        if idAttribute is 'FINGERPRINT_ID'
          @listenTo content, 'create', ->
            collection.create()

        layouts.sidebar.show sidebar
        layouts.content.show content
        content.$el.hide()

        categories.fetch
          reset   : true
          wait    : true
          success : ->
            section = categories.get categoryId, true
            sidebar.select section, false if categoryId

            categories.trigger "select", section, id


    # Initializers And Finalizers
    # ---------------------------
    Module.addInitializer (options) ->
      App.Controllers.Analysis = new AnalysisController

      # Стартуем контроллер конфигурации
      App.Configuration.show()

    Module.addFinalizer ->
      App.Controllers.Analysis.destroy()
      delete App.Controllers.Analysis
      App.Configuration.hide()
