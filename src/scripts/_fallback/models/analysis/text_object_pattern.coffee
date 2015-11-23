"use strict"

require "backbone.paginator"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.TextObjectPatternItem extends App.Common.BackbonePaginationItem

      idAttribute: "TEXT_OBJECT_PATTERN_ID"

      nameAttribute: "TEXT"

      urlRoot: "#{App.Config.server}/api/textObjectPattern"

      type: 'text_object_pattern'

      onCellCanEdit: (field) ->
        if field is "IS_SYSTEM" and +@get(field) is 1
          return false
        true

      islock: (o) ->
        o = action: o if _.isString o

        o.type = 'text_object'
        super o

      defaults:
        ENABLED   : 1
        NOTE      : null
        IS_REGEXP : 0
        TEXT      : ""

      validation:
        NOTE: [
          required  : false
          maxLength : 1000
        ],
        TEXT: [
          required : true
          rangeLength : [1, 256]
        ]

    class App.Models.Analysis.TextObjectPattern extends App.Common.BackbonePagination

      model: App.Models.Analysis.TextObjectPatternItem

      buttons: [ "create", "edit", "activate", "deactivate", "delete" ]

      toolbar: ->
        create: (selected) =>
          return true unless @section
          false

        show: (selected) ->
          return true if selected.length isnt 1
          return true if selected[0].isSystem()

          false

        edit: (selected) ->
          return true if selected.length isnt 1
          return true if selected[0].isSystem()
          false

        delete: (selected) ->
          return true unless selected.length
          return true if selected[0].isSystem()
          false

        activate: (selected) ->
          return true unless selected.length
          if selected.length is 1
            return true if selected[0].isSystem()
            return false unless selected[0].isEnabled()
          true

        deactivate: (selected) ->
          return true unless selected.length
          if selected.length is 1
            return true if selected[0].isSystem()
            return false if selected[0].isEnabled()
          true

      config: ->
        draggable: false
        default : sortCol: "TEXT"
        columns: [
          id          : "ENABLED"
          name        : ""
          menuName    : App.t 'global.status'
          field       : "ENABLED"
          width       : 32
          cssClass    : "center"
          resizable   : false
          sortable    : true
          formatter   : (row, cell, value, columnDef, dataContext) ->
            str = if +dataContext.get(columnDef.field) then "" else "in"
            "<span class='protected__itemIcon _#{str}active'></span>"
        ,
          id      : "TEXT"
          name    : App.t 'analysis.text_object_pattern.text_column'
          field   : "TEXT"
          resizable : true
          sortable  : true
          minWidth  : 200
          editor    : Slick.BackboneEditors.Text
          formatter : (row, cell, value, columnDef, dataContext) ->
            if +dataContext.get('IS_SYSTEM')
              App.t 'analysis.text_object_pattern.system_template'
            else
              dataContext.get columnDef.field
        ,
          id      : "NOTE"
          name    : App.t 'analysis.text_object_pattern.description_column'
          resizable : true
          sortable  : true
          minWidth  : 50
          field   : "NOTE"
          editor    : Slick.BackboneEditors.Text
        ]

      islock: (o) ->
        o = action: o if _.isString o

        o.type = 'text_object'
        super o

      sortCollection: (args) ->
        # TODO: убрать этот метод или использовать наследование;
        data = {}
        data.sort = {}
        data.sort[args.field] = args.direction
        @sortRule = data

        if @selected_text_object
          data.filter = {}
          data.filter["TEXT_OBJECT_ID"] = @selected_text_object.get("TEXT_OBJECT_ID")

        @fetch reset: true
