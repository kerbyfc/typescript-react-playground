"use strict"

entry = require "common/entry.coffee"
require "models/analysis/fingerprint.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.ProtectedDocuments extends Backbone.Collection

    class App.Models.Analysis.TableConditionColumnItem extends App.Common.ValidationModel

      idAttribute: "ind"

      model2sectionAttribute: 'table2category'

      nameAttribute: "column"

    class App.Models.Analysis.TableConditionColumn extends App.Common.BackboneLocalPagination

      model: App.Models.Analysis.TableConditionColumnItem

      config: ->
        default:
          sortCol   : 'column'
          sortable  : true
          draggable : false
          checkbox  : false

        columns: [
          id        : "ind"
          name      : ''
          field     : "ind"
          resizable : true
          sortable  : true
          width     : 50
        ,
          id        : "column"
          name      : App.t 'analysis.table.column_col'
          field     : "column"
          resizable : true
          sortable  : true
          minWidth  : 150
        ]

    class App.Models.Analysis.TableConditionItem extends App.Common.ValidationModel

      idAttribute: "CONDITION_ID"

      type: "table_condition"

      getName: ->
        name = super
        return @t 'entry.table.default_condition' if name is 'default'
        name

      minRows: (value, attr, computedState) ->
        if value < 0
          return @t 'entry.table.MIN_ROWS_number_error'

      validateHasMaxColNumber: (value, attr, computedState) ->
        max_column = _.max value.match(/(\d+)/ig), (val) -> parseInt(val, 10)

        if max_column > 32
          return App.t 'analysis.table.condition_column_num_32_violation_error'

      save: (data, options) ->
        check = @set data, validate: true
        return unless check
        @collection.add @
        options.success @

      destroy: ->
        @collection.remove @
        null

      defaults: ->
        data = MIN_ROWS: 10
        return data unless section = @collection?.section
        data[section.idAttribute] = section.id
        data

      validation:
        DISPLAY_NAME: [
          required : true
        ,
          rangeLength : [1, 128]
        ,
          fn: (name) ->
            model = @collection.findWhere DISPLAY_NAME: name
            if model and model isnt @
              App.t "form.error.unique",
                postProcess: 'sprintf'
                sprintf: [
                  App.t 'analysis.table.condition_display_name'
                ]
        ]
        NOTE: [
          required: false
        ,
          rangeLength : [0, 1000]
          msg     : App.t 'form.error.note_length'
        ]
        MIN_ROWS: [
          fn: 'minRows'
        ]
        VALUE: [
          required : true
        ,
          rangeLength : [1, 256]
        ,
          pattern : ///^(?:(?:\d{1,2}\s{0,1}\*{0,1}\s{0,1})|
            (?:\s{0,1}\(\s{0,1}\d{1,2}\s{0,1}\*{0,1}\s{0,1}(?:\|\s{0,1}\d{1,2}\s{0,1}\*{0,1}\s{0,1})*\s{0,1}\)\s{0,1}))
            (?:\s{0,1}\+\s{0,1}(?:(?:\d{1,2}\s{0,1}\*{0,1}\s{0,1})|
            (?:\s{0,1}\(\s{0,1}\d{1,2}\s{0,1}\*{0,1}\s{0,1}(?:\|\s{0,1}\d{1,2}\s{0,1}\*{0,1}\s{0,1})*\s{0,1}\)\s{0,1})))*$///
          msg   : 'analysis.table.condition_syntax_validation_error'
        ,
          fn: 'validateHasMaxColNumber'
        ,
          fn: (value) ->
            values = @collection.map (model) =>
              if model is @
                return null
              model.get('VALUE').replace /\s/g, ''

            values = _.compact values

            if value.replace(/\s/g, '') in values
              App.t "form.error.unique",
                postProcess: 'sprintf'
                sprintf: [
                  App.t 'analysis.table.value'
                ]
        ,
          fn: (value) ->
            max_column = _.max value.match(/(\d+)/ig), (val) -> parseInt(val, 10)
            if +max_column > JSON.parse(@collection.section.get('CONDITION_COLUMNS')).length
              return 'analysis.table.condition_column_num_validation_error'
        ]

      islock: (o) ->
        o = action: o if _.isString o

        o.type = 'table'
        super o

    class App.Models.Analysis.TableCondition extends App.Common.BackboneLocalPagination

      model: App.Models.Analysis.TableConditionItem

      buttons: [ "create", "edit", "delete" ]

      config: ->
        sortable : true
        draggable: false
        maxViewItems : null

        columns: [
          id       : "DISPLAY_NAME"
          name     : App.t 'global.DISPLAY_NAME'
          field    : "DISPLAY_NAME"
          sortable : true
          width    : 200
          formatter : (row, cell, value, columnDef, dataContext) ->
            dataContext.getName()
        ,
          id       : "VALUE"
          name     : App.t 'global.rule'
          field    : "VALUE"
          sortable : true
          width    : 370
        ,
          id       : "MIN_ROWS"
          name     : App.t 'global.row', context: 'many_min_count'
          field    : "MIN_ROWS"
          sortable : true
          width    : 200
        ]

      toolbar: ->
        create: (selected) ->
          if @length > 19
            return [2, App.t('entry.table.conditions_limit_error')]

        delete: (selected) ->
          return true unless selected.length

          pd = selected[0].get 'protected_documents'
          if pd?.length
            title = Marionette.Renderer.render "controls/popover/pd_error",
              name     : selected[0].getName()
              type     : selected[0].type
              document : _.pluck(pd, 'DISPLAY_NAME')

            return [2, title]

          false

      islock: (o) ->
        o = action: o if _.isString o

        o.type = 'table'
        super o

    class App.Models.Analysis.TableItem extends App.Models.Analysis.FingerprintItem

      type: 'table'

      urlRoot: "#{App.Config.server}/api/EtTable"

      model2sectionAttribute: 'table2category'

      collections: ->
        _.extend
          conditions          : App.Models.Analysis.TableCondition
          protected_documents : App.Models.Analysis.ProtectedDocuments
        , super

      deserialize: ->
        data = super
        data.conditions = new App.Models.Analysis.TableCondition data.conditions
        data.conditions.section = @
        data

      validate: (data) ->
        error = super

        unless data.conditions.length
          error ?= {}
          error.misc = [ 'analysis.table.condition_validation_error' ]

        if data.conditions.length > 20
          error ?= {}
          error.misc = [ 'analysis.table.max_conditions_error' ]
        error

    class App.Models.Analysis.Table extends App.Models.Analysis.Fingerprint

      model: App.Models.Analysis.TableItem

      maxFileSize: 2147483648

      buttons: [ "create", "edit", "delete" ]

      config : ->
        formats = App.request('bookworm', 'fileformat').pretty()

        draggable: true
        default : sortCol: "DISPLAY_NAME"
        columns : [
          id      : "DISPLAY_NAME"
          name    : App.t 'analysis.table.display_name_column'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "MIME"
          name    : App.t 'analysis.table.filetype_column'
          field   : "MIME"
          resizable : true
          minWidth  : 150
          formatter : (row, cell, value, columnDef, dataContext) ->
            formats[dataContext.get(columnDef.field)]?[0].name ? dataContext.get(columnDef.field)
        ,
          id      : "SOURCE"
          name    : App.t 'global.update_mode'
          field   : "SOURCE"
          resizable : true
          minWidth  : 150
          formatter : (row, cell, value, columnDef, dataContext) ->
            type = if dataContext.get(columnDef.field) is 'user' then 'manual' else 'auto'
            App.t "global.#{type}"
        ,
          id      : "FILE_PATH"
          name    : App.t 'analysis.table.filename_column'
          field   : "FILE_PATH"
          resizable : true
          sortable  : true
          minWidth  : 150
        ,
          id      : "FILE_SIZE"
          name    : App.t 'analysis.table.file_size_column'
          field   : "FILE_SIZE"
          resizable : true
          sortable  : true
          minWidth  : 100
          formatter : (row, cell, value, columnDef, dataContext) ->
            App.Helpers.getBytesWithUnit dataContext.get(columnDef.field)
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
          id      : "NOTE"
          name    : App.t 'analysis.table.note_column'
          resizable : true
          sortable  : true
          minWidth  : 200
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]
