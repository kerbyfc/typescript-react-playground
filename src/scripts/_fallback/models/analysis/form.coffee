"use strict"

require "models/analysis/fingerprint.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.FormItem extends App.Models.Analysis.FingerprintItem

      model2sectionAttribute: 'form2category'

      type: 'form'

      urlRoot: "#{App.Config.server}/api/EtForm"

      defaults:
        DISPLAY_NAME       : ""
        NOTE               : ""
        DETECT_FILLED_FORM : 1

      deserialize: ->
        data = super
        formats = App.request('bookworm', 'fileformat').pretty()
        data.MIME = formats[data.MIME]?[0].name or data.MIME
        data

    class App.Models.Analysis.Form extends App.Models.Analysis.Fingerprint

      model: App.Models.Analysis.FormItem

      maxFileSize: 31457280

      buttons: [ "create", "edit", "delete" ]

      config: ->
        draggable: true
        default : sortCol: "DISPLAY_NAME"
        columns : [
          id      : "DISPLAY_NAME"
          name    : App.t 'analysis.form.display_name_column'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "MIME"
          name    : App.t 'analysis.form.filetype_column'
          field   : "MIME"
          resizable : true
          minWidth  : 150
          formatter : (row, cell, value, columnDef, dataContext) ->
            formats = App.request('bookworm', 'fileformat').pretty()
            formats[dataContext.get(columnDef.field)]?[0].name ? dataContext.get(columnDef.field)
        ,
          id      : "FILE_PATH"
          name    : App.t 'analysis.form.filename_column'
          field   : "FILE_PATH"
          resizable : true
          sortable  : true
          minWidth  : 150
        ,
          id      : "FILE_SIZE"
          name    : App.t 'analysis.form.file_size_column'
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
          name    : App.t 'analysis.form.note_column'
          resizable : true
          sortable  : true
          minWidth  : 200
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]
