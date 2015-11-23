"use strict"

helpers = require "common/helpers.coffee"
require "common/backbone-tree.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Protected ?= {}

    class App.Models.Protected.CatalogItem extends App.Common.ModelTree

      type: 'catalog'

      entryType: 'document'

      idAttribute: "CATALOG_ID"

      parentIdAttribute: "PARENT_CATALOG_ID"

      childrenCountAttribute: 'CATALOG_COUNT'

      countAttribute: "DOCUMENT_COUNT"

      urlRoot: "#{App.Config.server}/api/protectedCatalog"

      getItem: ->
        title        : @getName()
        key          : @id
        extraClasses : if @isEnabled() then 'fancytreeItem__protectedObj active' else 'fancytreeItem__protectedObj inactive'
        data         : @toJSON()

      isRoot: ->
        return true if @get(@nameAttribute) is '<root>'
        false

      defaults: ->
        o =
          ENABLED           : 1
          PARENT_CATALOG_ID : @collection.getRootModel()?.id

        selected = @collection.getSelectedModels?()
        return o if not selected or not selected.length

        parent = selected[0]
        _.extend o,
            PARENT_CATALOG_ID : parent.id
            ENABLED           : parent.get('ENABLED')

      error: (err) ->
        return unless err

        if 'DISPLAY_NAME' of err
          err.DISPLAY_NAME = _.map err.DISPLAY_NAME, (message) ->
            App.t "protected.catalog.#{message}",
              postProcess: 'sprintf'
              sprintf: [
                App.t "global.DISPLAY_NAME"
              ]
              defaultValue: message

        err

      validation:
        DISPLAY_NAME: [
          required : true
          msg    : App.t 'analysis.category.category_required_validation_error'
        ,
          rangeLength : [1, 256]
          msg     : App.t 'analysis.category.category_name_length_validation_error'
        ]
        NOTE: [
          required  : false
        ,
          rangeLength : [0, 1000]
          msg     : App.t 'protected.catalog.note_length_validation_error'
        ]

    class App.Models.Protected.Catalog extends App.Common.CollectionTree

      acceptTypes: '.zip'

      url: "#{App.Config.server}/api/protectedCatalog"

      model: App.Models.Protected.CatalogItem

      islock: (data) ->
        data = action: data if _.isString data

        if not data.action or data.action is 'show'
          data =
            module : 'protected'
            action : 'show'

        if data.action and ( data.action is 'export' or data.action is 'import' )
          data =
            module : 'protected'
            action : 'import'

        if data.action is 'policy'
          data =
            type   : 'policy_object'
            action : 'edit'

        super data

      buttons: [ "create", "edit", "delete", "activate", "deactivate", "import", "export", "policy" ]

      toolbar: ->
        create: (selected) ->
          return false unless selected.length
          return false if selected[0].isRoot()

          node =  @getNodeByKey(selected[0].id)
          return [
            2
            selected[0].t 'level',
              max   : 7
              context : 'error'
          ] if node and node.getLevel() > 6

          false

        edit: (selected) ->
          return true if selected.length isnt 1
          return true if selected[0].isRoot()
          false

        delete: (selected) ->
          return true if selected.length isnt 1
          return true if selected[0].isRoot()
          false

        activate: (selected) ->
          return true unless selected.length
          parent = selected[0].getParentModel()
          return true if selected[0].isRoot()
          return true if parent and not parent.isEnabled()
          return true if selected[0].isEnabled()
          false

        deactivate: (selected) ->
          return true unless selected.length
          parent = selected[0].getParentModel()
          return true if selected[0].isRoot()
          return true if parent and not parent.isEnabled()
          return true unless selected[0].isEnabled()
          false
