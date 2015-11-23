"use strict"

require "models/protected/catalog.coffee"
require "fancytree"

App.module "Dashboards.Dialogs",
  startWithParent: true
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards ?= {}

    class App.Views.Dashboards.SelectProtectedCatalogDialog extends Marionette.ItemView

      template: "dashboards/dialogs/select_protected_catalogs"

      ui:
        tree: '.tree_view'

      events:
        "click .-success": "save"

      initialize: (options) ->
        @callback = options.callback
        @title = options.title
        @selected = options.selected

        @collection = new App.Models.Protected.Catalog

      save: (e) ->
        e.preventDefault()

        @tree = @ui.tree.fancytree('getTree')

        @callback(@tree.getSelectedNodes(true))

        @destroy()

      onShow: ->
        @$el.i18n()

        @collection.fetch
          reset: true
          success: =>
            @ui.tree.fancytree
              checkbox: true
              source: @collection.getItems
              debugLevel: 0

              init: =>
                root_node = @ui.tree.fancytree('getRootNode')
                root_node.sortChildren()

                _.each root_node.getChildren(), (node) ->
                  node.setExpanded(true)

                if @selected.length
                  root_node.visit (node) =>
                    node.setSelected true if @selected.indexOf(node.key) isnt -1

      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
