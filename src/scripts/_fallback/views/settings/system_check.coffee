"use strict"

require "views/controls/table_view.coffee"

module.exports = class SystemCheckView extends Marionette.LayoutView

  className: 'content'

  regions:
    systemChecksRegion: '#system_check_list'

  template: 'settings/system_check'

  ui:
    toolbar_refresh       : "[data-action='refresh']"
    crash_notice_settings : '#crash_notice_settings'

  triggers:
    "click @ui.toolbar_refresh"           : "refresh_sensors"
    "click [data-action='edit_settings']" : "edit_settings"

  templateHelpers: ->
    server_name: @options.server_name
    settings: @options.settings

  initialize: ->
    @systemChecksTableView = new App.Views.Controls.TableView
      collection: @collection
      config:
        default:
          editable: false
          autoHeight: true
        columns: [
          {
            id      : "status"
            name    : ''
            field   : "status"
            width   : 40
            resizable : false
            formatter : (row, cell, value, columnDef, dataContext) ->
              switch dataContext.get(columnDef.field)
                when 0
                  "<div class='tag__color' data-color='#8cc152'></div>"
                when 1
                  "<div class='tag__color' data-color='#f6bb42'></div>"
                when 2, 3
                  "<div class='tag__color' data-color='#da4453'></div>"
          }
          {
            id      : "name"
            name    : App.t 'settings.healthcheck.name'
            field   : "name"
            resizable : true
            minWidth  : 200
            formatter : (row, cell, value, columnDef, dataContext) ->
              locale = App.t('settings.healthcheck.checks', { returnObjectTrees: true })

              if locale[dataContext.get(columnDef.field)]
                locale[dataContext.get(columnDef.field)]
              else
                dataContext.get(columnDef.field)
          }
          {
            id      : "value"
            name    : App.t 'settings.healthcheck.details'
            field   : "value"
            minWidth  : 300
          }
        ]

  onShow: ->
    # Подписываемся у пользователя на события обновления счетчиков
    @listenTo App.Session.currentUser(), 'message', (message) =>
      if message.data.module is 'refresh_sensors' then @collection.fetch(reset: true)

    @systemChecksRegion.show @systemChecksTableView

    @listenTo App, "resize", (args) =>
      @systemChecksTableView.resize null, App.Layouts.Application.content.$el.width()

    @systemChecksTableView.resize null, App.Layouts.Application.content.$el.width()

    @ui.crash_notice_settings.html Marionette.Renderer.render "settings/dialogs/crash_notice_info", _.assign @, @options.settings.toJSON()

    @listenTo @options.settings, 'change', =>
      @ui.crash_notice_settings.html Marionette.Renderer.render "settings/dialogs/crash_notice_info", _.assign @, @options.settings.toJSON()

  onClose: ->
    @stopListening App.Session.currentUser(), "message"
