"use strict"

require "backbone.paginator"
helpers = require 'common/helpers.coffee'

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.TermItem extends App.Common.BackbonePaginationItem

      idAttribute: "TERM_ID"

      nameAttribute: 'TEXT'

      model2sectionAttribute: 'term2category'

      urlRoot: "#{App.Config.server}/api/term"

      type: 'term'

      morphology: [
        "ukr"
        "tur"
        "srp"
        "spa"
        "rus"
        "ron"
        "pol"
        "lav"
        "ita"
        "fra"
        "eng"
        "deu"
        "bel"
        "aze"
        "ara"
      ]

      deserialize: ->
        data = super
        data = _.extend data, t2c.toJSON() if t2c = @getSection()
        data

      defaults: ->
        section = @collection.section
        return unless section

        MORPHOLOGY     : section.get "TERM_MORPHOLOGY"
        LANGUAGE       : section.get "TERM_LANGUAGE"
        CASE_SENSITIVE : section.get "TERM_CASE_SENSITIVE"
        term2category: [
          CATEGORY_ID    : section.id
          WEIGHT         : +section.get "TERM_WEIGHT"
          ENABLED        : 1
          CHARACTERISTIC : 0
        ]

      validate: (attr) ->
        err = super
        if +attr.WEIGHT is 0 and attr.CHARACTERISTIC is 0
          err ?= {}
          err.WEIGHT = App.t 'analysis.category.category_term_weight_validation_error'

        err

      validation:
        TEXT: [
          required: true
        ,
          rangeLength : [1, 256]
        ]
        WEIGHT: [
          required: true
        ,
          range : [1, 10]
          msg   : App.t 'analysis.category.category_term_weight_validation_error'
        ]

      relation: ->
        CHARACTERISTIC: (value) ->
          _data = field: 'WEIGHT'
          _data.disabled = if value then true else false
          _data

        CASE_SENSITIVE: (value) ->
          return unless value
          field : 'MORPHOLOGY'
          value : 0

        MORPHOLOGY: (value) ->
          return unless value
          field : 'CASE_SENSITIVE'
          value : 0

        LANGUAGE: (value) =>
          _data = field: 'MORPHOLOGY'
          isMophology = value in @morphology
          _data.disabled = if isMophology then false else true
          _data.hide = if isMophology then false else true
          if @isNew()
            _data.value = if isMophology then @get('MORPHOLOGY') else 0
          _data

      inlineSave: (field, value) ->
        if $.inArray(field, ['CHARACTERISTIC', 'WEIGHT']) isnt -1
          section = @collection.section
          term2category = @get('term2category').toJSON()
          t2c = _.find term2category, 'CATEGORY_ID': section.id

          if field is 'CHARACTERISTIC' and +value is 1
            t2c.WEIGHT = null

          if field is 'CHARACTERISTIC' and +value is 0
            t2c.WEIGHT = section.get 'TERM_WEIGHT'

          t2c[field] = value

          super 'term2category', term2category
        else
          super

      error: ->
        err = super
        if err.CASE_SENSITIVE and err.LANGUAGE and err.TEXT
          misc: [err.TEXT]
        else
          err

      onCellCanEdit: (field) ->
        if field is "WEIGHT"
          t2c = @get('term2category').where
            'CATEGORY_ID': @collection.section.get 'CATEGORY_ID'
          if parseInt(t2c[0].get("CHARACTERISTIC"), 10) is 1
            return false

        if field is 'MORPHOLOGY'
          if @get("LANGUAGE") in @morphology
            return false
        true

    class App.Models.Analysis.Term extends App.Common.BackbonePagination

      model: App.Models.Analysis.TermItem

      buttons: [ "create", "edit", "delete" ]

      toolbar: ->
        create: (selected) =>
          section = @getSection()
          if section and section.getChildrenCount() is 0
            return false
          true

      config: ->
        autosizeColumns : true
        draggable   : true
        default     : sortCol: "TEXT"
        columns: [
          id      : "TEXT"
          name    : App.t 'analysis.term.text_column'
          field   : "TEXT"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id       : "CHARACTERISTIC"
          name     : App.t 'analysis.term.characteristic_column'
          resizable  : true
          sortable   : true
          minWidth   : 50
          field    : "CHARACTERISTIC"
          cssClass   : "center"
          applyValue : (item, value) ->
          loadValue  : (item) ->
            t2c = item.get('term2category').where 'CATEGORY_ID': item.collection.section.get 'CATEGORY_ID'
            if t2c.length
              t2c[0].get 'CHARACTERISTIC'
            else
              null
          locale: App.t 'global', returnObjectTrees: true
          formatter: (row, cell, value, columnDef, dataContext) ->
            section = dataContext.collection.section
            locale = App.t 'global', returnObjectTrees: true

            if section
              t2c = dataContext.get('term2category').where 'CATEGORY_ID': section.get 'CATEGORY_ID'

              if t2c.length
                if parseInt(t2c[0].get(columnDef.field), 10) then locale.yes or "Yes" else locale.no or "No"

          editor : Slick.BackboneEditors.YesNoSelect
        ,
          id       : "WEIGHT"
          name     : App.t 'analysis.term.weight_column'
          resizable  : true
          sortable   : true
          minWidth   : 50
          field    : "WEIGHT"
          cssClass   : "center"
          applyValue : (item, value) ->
          loadValue  : (item) ->
            t2c = item.get('term2category').where 'CATEGORY_ID': item.collection.section.get 'CATEGORY_ID'
            if t2c.length
              t2c[0].get 'WEIGHT'
            else
              null
          formatter: (row, cell, value, columnDef, dataContext) ->
            section = dataContext.collection.section

            if section
              t2c = dataContext.get('term2category').where 'CATEGORY_ID': section.get 'CATEGORY_ID'

              return t2c[0]?.get(columnDef.field)
          editor       : Slick.BackboneEditors.Integer
          editorMinValue : 1
          editorMaxValue : 10
        ,
          id      : "CASE_SENSITIVE"
          name    : App.t 'analysis.term.case_sensitive_column'
          resizable : true
          sortable  : true
          minWidth  : 50
          field   : "CASE_SENSITIVE"
          cssClass  : "center"
          locale    : App.t 'global', returnObjectTrees: true
          formatter : Slick.BackboneFormatters.YesNo
        ,
          id      : "MORPHOLOGY"
          name    : App.t 'analysis.term.morphology_column'
          resizable : true
          sortable  : true
          minWidth  : 50
          field   : "MORPHOLOGY"
          cssClass  : "center"
          locale    : App.t 'global', returnObjectTrees: true
          formatter : Slick.BackboneFormatters.YesNo
          editor    : Slick.BackboneEditors.YesNoSelect
        ,
          id      : "LANGUAGE"
          name    : App.t 'analysis.term.language'
          resizable : true
          sortable  : true
          minWidth  : 120
          cssClass  : "center"
          field   : "LANGUAGE"
          formatter : (row, cell, value, columnDef, dataContext) =>
            @title = @getLanguage(dataContext.get(columnDef.field))
            "<img src='/img/languages/language-#{dataContext.get(columnDef.field)}.png' \
             title='#{@title.title}'> #{@title.title}"
          editor        : Slick.BackboneEditors.Select
          editorValues    : @getLanguages()
          editor_img_prefix : "languages/language-"
        ,
          id      : "CREATE_DATE"
          name    : App.t 'global.create_date'
          field   : "CREATE_DATE"
          resizable : true
          sortable  : true
          minWidth  : 100
          formatter : (row, cell, value, columnDef, dataContext) ->
            moment.utc(dataContext.get(columnDef.field)).local().format('L LT')
        ]

      sortCollection: (args) ->
        # Если сортируем по элементам вложенным в связь
        # то кидаем сортировку в связь
        if $.inArray(args.field, ['CHARACTERISTIC', 'WEIGHT']) isnt -1
          args.field = 'sort_term2category.' + args.field

        super

      getLanguages: ->
        _.map helpers.getLanguages(), (title, key) ->
          key   : key
          title : title

      getLanguage: (lang) ->
        key   : lang
        title : helpers.getLanguages lang
