"use strict"

style = require "common/style.coffee"
require "backbone.paginator"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.FingerprintItem extends App.Common.BackbonePaginationItem

      idAttribute: "FINGERPRINT_ID"

      model2sectionAttribute: 'fingerprint2category'

      type: 'fingerprint'

      urlRoot: "#{App.Config.server}/api/fingerprint"

      update: (isReplace) ->
        unless _.isBoolean isReplace
          return @trigger "update"

      deserialize: ->
        data = super
        formats = App.request('bookworm', 'fileformat').pretty()
        data.MIME = formats[data.MIME]?[0].name or data.MIME
        data

    class App.Models.Analysis.Fingerprint extends App.Common.BackbonePagination

      model: App.Models.Analysis.FingerprintItem

      maxFileSize: 128000000

      buttons: [ "create", "edit", "delete" ]

      config: ->
        formats = App.request('bookworm', 'fileformat').pretty()

        draggable: true
        default: sortCol: "DISPLAY_NAME"
        columns: [
          id      : "DISPLAY_NAME"
          name    : App.t 'analysis.fingerprint.display_name_column'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
        ,
          id      : "MIME"
          name    : App.t 'analysis.fingerprint.filetype_column'
          field   : "MIME"
          resizable : true
          minWidth  : 150
          formatter : (row, cell, value, columnDef, dataContext) ->
            return dataContext unless formats
            formats[dataContext.get(columnDef.field)]?[0].name ? dataContext.get(columnDef.field)
        ,
          id      : "FILE_PATH"
          name    : App.t 'analysis.fingerprint.filename_column'
          field   : "FILE_PATH"
          resizable : true
          sortable  : true
          minWidth  : 150
        ,
          id      : "FILE_SIZE"
          name    : App.t 'analysis.fingerprint.file_size_column'
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
          name    : App.t 'analysis.fingerprint.note_column'
          resizable : true
          sortable  : true
          minWidth  : 200
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]

      create: ->
        proto = @model::
        type = proto.type
        url  = proto.urlRoot.split('api/').pop()
        section = @getSection()

        App.notify.fileupload
          multiple : true
          url    : "#{App.Config.server}/api/#{url}/compile"
          add    : (e, data) =>
            files = _.map data.files, (file) =>
              o =
                type      : type
                action    : "create"
                name      : file.name
                state     : "upload"
                sectionId : section.id
                module    : App.currentModule.moduleName.toLowerCase()
                percent   : 0
                size      : file.size

              if o.size > @maxFileSize
                o.state = "error"
                o.error = App.t "analysis.#{type}.contstraint_max_size_error"
              o

            _.each files, (file) ->
              if file.state is 'error'
                App.notify.add file
                return

              o = STATUS: 'ready'

              o[proto.nameAttribute] = file.name

              if section
                o["#{type}2category"] = JSON.stringify [ CATEGORY_ID: section.id ]

              if type is 'fingerprint'
                _.extend o,
                  TEXT_VALUE_THRESHOLD : section?.get('FP_TEXT_VALUE_THRESHOLD') or 10
                  BIN_VALUE_THRESHOLD  : section?.get('FP_BIN_VALUE_THRESHOLD') or 10

              o[section.idAttribute] = section.id if section

              options =
                files    : data.files
                cid      : file.cid
                formData : o
                options  : file

              App.notify.send options

      initialize: ->
        super
        type = @model::type

        fetch = _.throttle @fetch, @timeoutAutoRefresh

        @listenTo App.vent, "analysis:create", (state, data) =>
          model = App.notify.get data.key
          return unless model

          if state is 'save'
            if data.errors?.length
              state = 'error'
              message = data.errors[0].message
              message = message.DISPLAY_NAME or message
              message = @model::t message,
                item    : data.errors.model or data.errors[0]?.model
                context : 'error'
                name    : 'DISPLAY_NAME'
              model.set 'error', message
            else
              state = 'updated' if model.get('action') is 'update'
              fetch.apply @ if @length < @perPage

          model.set
            percent : data.progress
            state   : state

          # TODO: KAKTYZ-4498 вернуться к реализации ошибок после того, как будет
          # предоставлена информация о формате ошибок
          if state is 'error' and data.message
            switch data.message
              when 'bad_extension'
                error = App.t "form.error.not_allowed_file_extension"
              when 'file_not_saved', 'validation_failed'
                error = App.t "form.error.#{data.message}"
              when 'duplicate', 'not_unique'
                error = App.t "form.error.duplicate", item: data.model
              when 'sample_compiler_not_found'
                error = App.t "analysis.#{type}.sample_compiler_not_found"
              when 'internal_error'
                error = App.t "analysis.undefined_error"
              when 'not_match_delimiter'
                error = App.t "entry.table.not_match_delimiter"
              when 'few_rows'
                error = App.t "analysis.#{type}.few_rows_error"
              when 'max_columns'
                error = App.t "analysis.#{type}.max_columns_error"
              when 'max_words'
                error = App.t "entry.#{type}.max_words_error"
              else
                error = data.message

            model.set 'error', error
