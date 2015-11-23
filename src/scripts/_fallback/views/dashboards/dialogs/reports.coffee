"use strict"

module.exports =class App.Views.Dashboards.ReportsDialog extends Marionette.LayoutView

  template: "dashboards/dialogs/reports"

  regions:
    reports_table           : "#reports_table"
    reports_paginator         : "#reports_paginator"

  templateHelpers: ->
    modal_dialog_title: @options.title

  initialize: (options) ->
    @reports_paginator_ = new App.Views.Controls.Paginator
      collection: @collection

    @reports_table_ = new App.Views.Controls.TableView
      collection: @collection
      config:
        default:
          checkbox: false
          sortCol: "CREATE_DATE"
        columns: [
          {
            id      : "DISPLAY_NAME"
            name    : App.t 'dashboards.dashboards.display_name_column'
            field   : "DISPLAY_NAME"
            resizable : true
            sortable  : true
            minWidth  : 150
          }
          {
            id      : "CREATE_DATE"
            name    : App.t 'dashboards.dashboards.report_date'
            field   : "CREATE_DATE"
            resizable : true
            sortable  : true
            minWidth  : 150
            formatter     : (row, cell, value, columnDef, dataContext) ->
              if dataContext.get(columnDef.field)
                App.Helpers.show_datetime dataContext.get columnDef.field
          }
          {
            id      : "links"
            name    : App.t 'dashboards.dashboards.report_type'
            resizable : true
            minWidth  : 150
            field   : "links"
            formatter     : (row, cell, value, columnDef, dataContext) ->

              switch dataContext.get 'STATUS'
                when 0
                  App.t 'dashboards.dashboards.generating_report_processing'
                when 1
                  "<a href='/public/#{dataContext.get('HASH')}.pdf' target='_blank' class='link'>pdf<a/> |
                  <a href='/public/#{dataContext.get('HASH')}.html' target='_blank' class='link'>html<a/>"
                when 2
                  App.t 'dashboards.dashboards.generating_report_failed'
          }
        ]

  onShow: ->
    # Рендерим контролы
    @reports_table.show @reports_table_
    @reports_paginator.show @reports_paginator_

    @listenTo @reports_table_, "table:sort", _.bind(@collection.sortCollection, @collection)

    @reports_table_.resize 300, 600
