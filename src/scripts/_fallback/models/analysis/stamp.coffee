"use strict"

helpers = require "common/helpers.coffee"
require "models/analysis/fingerprint.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.StampItem extends App.Models.Analysis.FingerprintItem

      model2sectionAttribute: 'stamp2category'

      type: 'stamp'

      urlRoot: "#{App.Config.server}/api/EtStamp"

      deserialize: ->
        data = super
        formats = App.request('bookworm', 'fileformat').pretty()

        data.FILE_SIZE = helpers.getBytesWithUnit data.FILE_SIZE
        data.MIME = formats[data.MIME]?[0].name or data.MIME
        data

      validation:
        DISPLAY_NAME: [
          required: true
        ,
          rangeLength : [1, 256]
        ]

    class App.Models.Analysis.Stamp extends App.Models.Analysis.Fingerprint

      model: App.Models.Analysis.StampItem

      maxFileSize: 31457280

      buttons: [ "create", "edit", "delete" ]

      config: ->
        formats = App.request('bookworm', 'fileformat').pretty()

        draggable: true
        default: sortCol: "DISPLAY_NAME"
        columns: [
          id      : "DISPLAY_NAME"
          name    : App.t 'analysis.stamp.display_name_column'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "MIME"
          name    : App.t 'analysis.stamp.filetype_column'
          field   : "MIME"
          resizable : true
          minWidth  : 150
          formatter : (row, cell, value, columnDef, dataContext) ->
            formats[dataContext.get(columnDef.field)]?[0].name ? dataContext.get(columnDef.field)
        ,
          id      : "FILE_PATH"
          name    : App.t 'analysis.stamp.filename_column'
          field   : "FILE_PATH"
          resizable : true
          sortable  : true
          minWidth  : 150
        ,
          id      : "FILE_SIZE"
          name    : App.t 'analysis.stamp.file_size_column'
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
          name    : App.t 'global.NOTE'
          resizable : true
          sortable  : true
          minWidth  : 200
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]
