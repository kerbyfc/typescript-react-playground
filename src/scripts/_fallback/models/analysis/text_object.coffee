"use strict"

require "backbone.paginator"
helpers = require "common/helpers.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.TextObjectItem extends App.Common.BackbonePaginationItem

      idAttribute: "TEXT_OBJECT_ID"

      model2sectionAttribute: 'text_object2category'

      type: 'text_object'

      urlRoot: "#{App.Config.server}/api/textObject"

      add: (data, options) ->
        return unless @dupModel
        model = new @collection.model @dupModel, collection: @collection

        model.get('text_object2category').add data.text_object2category
        delete data.text_object2category
        model
        .save data, options
        .done =>
          @collection.fetch()
        null

      defaults: ->
        DISPLAY_NAME     : ""
        NOTE         : null
        TYPE         : "1"
        QUANTITY_THRESHOLD : 1

      validation:
        DISPLAY_NAME: [
          required: true
        ,
          rangeLength : [1, 256]
          msg     : App.t 'analysis.text_object.text_length_validation_error'
        ,
          not_unique_field: true
        ]
        QUANTITY_THRESHOLD:
          range : [1, 20]
          msg   : App.t 'analysis.text_object.quantity_threshold_validation_error'

      deserialize: ->
        data = super
        data.text_object_patterns = new App.Models.Analysis.TextObjectPattern data.conditions
        data.text_object_patterns.filterData = filter: TEXT_OBJECT_ID: @id
        data.text_object_patterns.section = @

        if not data.text_object_patterns.sortRule
          data.text_object_patterns.sortRule = sort : "TEXT" : "ASC"

        data

    class App.Models.Analysis.TextObject extends App.Common.BackbonePagination

      model: App.Models.Analysis.TextObjectItem

      buttons: [ "create", "edit", "delete", "addSystem" ]

      toolbar: ->
        addSystem: (selected) -> false

      islock: (data) ->
        data = 'create' if data is 'addSystem'
        super data

      config: ->
        draggable : true
        default   : sortCol: "DISPLAY_NAME"
        columns: [
          id      : "DISPLAY_NAME"
          name    : App.t 'analysis.text_object.display_name_column'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "CREATE_DATE"
          name    : App.t 'global.create_date'
          field   : "CREATE_DATE"
          resizable : true
          sortable  : true
          minWidth  : 100
          formatter : (row, cell, value, columnDef, dataContext) ->
            moment.utc(dataContext.get(columnDef.field)).local().format('L LT')
        ,
          id        : "COUNTRY"
          name      : App.t 'global.country'
          resizable : true
          sortable  : true
          minWidth  : 120
          cssClass  : "center"
          field     : "COUNTRY"
          formatter : (row, cell, value, columnDef, dataContext) ->
            helpers.getCountries dataContext.get columnDef.field
          editor        : Slick.BackboneEditors.Select
          editorValues  : _.map helpers.getCountries(), (title, key) ->
            key   : key
            title : title
        ,
          id      : "NOTE"
          name    : App.t 'analysis.text_object.description_column'
          resizable : true
          sortable  : true
          minWidth  : 200
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]
