"use strict"

require "backbone.paginator"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    class App.Models.Analysis.GraphicItem extends Backbone.Model

      idAttribute: "FINGERPRINT_ID"

      display_attr: 'DISPLAY_NAME'

      type: 'graphic'

      urlRoot: "#{App.Config.server}/api/EtGraphic"

    class App.Models.Analysis.Graphic extends App.Common.BackbonePagination

      model: App.Models.Analysis.GraphicItem

      buttons: []

      config: ->
        draggable : false
        default   : sortCol: "DISPLAY_NAME"
        columns : [
          id      : "DISPLAY_NAME"
          name    : App.t 'global.DISPLAY_NAME'
          field   : "DISPLAY_NAME"
          resizable : true
          sortable  : true
          minWidth  : 200
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
        ]
