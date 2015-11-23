"use strict"

require "views/controls/table_view.coffee"

module.exports = class EventsTable extends Marionette.LayoutView

  template: "events/events_table"

  className: 'objects'

  regions:
    objects_table     : '[data-region="table"]'

  initialize: ->
    @services = App.request 'bookworm', 'service'

    @columns = [
      {
        id              : "VIOLATION_LEVEL"
        name            : ''
        sortable        : true
        maxWidth        : 40
        minWidth        : 40
        field           : "VIOLATION_LEVEL"
        cssClass        : "center event-cell"
        formatter       : (row, cell, value, columnDef, dataContext) ->
          violation_level = dataContext.get(columnDef.field)?.toLowerCase()
          v_str = App.t "events.conditions.violation_level_#{violation_level}"
          if violation_level
            "<i class='[ eventDetails__threatIcon _#{violation_level} ]'
              title='#{ App.t 'events.conditions.violation_level'}: #{v_str}'
            ></i>"
      }
      {
        id       : "USER_DECISION"
        name     : ''
        sortable : true
        maxWidth : 40
        minWidth : 40
        field    : "USER_DECISION"
        cssClass : "center event-cell"

        formatter : (row, cell, value, columnDef, dataContext) ->
          user_decision_str = App.t "events.events.#{dataContext.get(columnDef.field)}"

          "<i class='[ icon _userDecision#{dataContext.get(columnDef.field)} ]'
            title='#{ App.t 'events.conditions.user_decision'}: #{user_decision_str}'
            ></i>"
      }
      {
        id       : "VERDICT"
        name     : ''
        sortable : true
        maxWidth : 40
        minWidth : 40
        field    : "VERDICT"
        cssClass : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          title_prefix = App.t 'events.conditions.verdict'
          "<i class='[ icon _verdict#{dataContext.get(columnDef.field)} ]'
            title='#{title_prefix}: #{ App.t 'events.conditions.verdict_' + dataContext.get(columnDef.field).toLowerCase()}'
            ></i>"
      }
      {
        id              : "OBJECT_TYPE_CODE"
        name            : ''
        sortable        : true
        maxWidth        : 40
        minWidth        : 40
        field           : "OBJECT_TYPE_CODE"
        cssClass        : "center event-cell"
        formatter       : (row, cell, value, columnDef, dataContext) ->
          return Marionette.Renderer.render "events/event_type", dataContext.toJSON()
      }
      {
        id              : "FORWARD_STATE_CODE"
        name            : ''
        sortable        : true
        maxWidth        : 40
        minWidth        : 40
        field           : "FORWARD_STATE_CODE"
        cssClass        : "center event-cell"
        formatter       : (row, cell, value, columnDef, dataContext) ->
          title_prefix = App.t 'events.conditions.forward_state_code'
          status = dataContext.get(columnDef.field)
          status_str = App.t "events.conditions.sent_statuses.#{status}"
          "<i class='[ icon _sendStatus#{status} ]' title='#{title_prefix}: #{status_str}'></i>"
      }
      {
        id        : "OBJECT_ID"
        name      : App.t 'events.conditions.object_id'
        field     : "OBJECT_ID"
        resizable : true
        sortable  : true
        minWidth  : 80
      }
      {
        id        : "OBJECT_ERROR_EXISTS"
        name      : App.t 'events.conditions.object_error_exists'
        resizable : true
        sortable  : true
        width     : 50
        field     : "OBJECT_ERROR_EXISTS"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if dataContext.get(columnDef.field)
            """<i class="[ icon _error ]" title='#{ App.t("events.events.event_has_error") }'></i>"""
      }
      {
        id        : "SENT_DATE"
        name      : App.t 'events.conditions.sent_date_column'
        resizable : true
        sortable  : true
        minWidth  : 260
        field     : "SENT_DATE"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if dataContext.get(columnDef.field)
            "#{moment.utc("#{dataContext.get(columnDef.field)}").local()
            .format('DD/MM/YYYY HH:mm:ss')}"
      }
      {
        id        : "senders"
        name      : App.t 'events.conditions.senders_column'
        resizable : true
        sortable  : true
        minWidth  : 250
        field     : "senders"
        cssClass  : "event-cell"

        asyncPostRender : (cellNode, row, dataContext, colDef) ->
          participantView = Marionette.ItemView.extend
            behaviors:
              EntityInfo:
                targets       : '.popover_info'
                behaviorClass : App.Behaviors.Events.EntityInfo

            template: "events/partials/_participant"

            serializeModel: (model) ->
              _.assign @model.toJSON(),
                participants_keys      : dataContext.get "senders_keys"
                participants           : dataContext.get "senders"
                participants_conflicts : dataContext.get "senders_conflicts"
                participant_type       : "sender"
                without_title          : true

          view = new participantView
            model: dataContext

          view.render()
          $(cellNode).empty().append view.$el

        formatter       : (row, cell, value, columnDef, dataContext) ->
          Marionette.Renderer.render "events/partials/_participant", _.assign dataContext.toJSON(),
            participants_keys      : dataContext.get "senders_keys"
            participants           : dataContext.get "senders"
            participants_conflicts : dataContext.get "senders_conflicts"
            participant_type       : "sender"
            without_title          : true
      }
      {
        id              : "workstations"
        name            : App.t 'events.conditions.workstations'
        resizable       : true
        sortable        : true
        minWidth        : 150
        field           : "workstations"
        cssClass        : "event-cell"
        formatter       : (row, cell, value, columnDef, dataContext) ->
          _.map dataContext.get('workstations'), (workstation) ->
            if workstation.DISPLAY_NAME then workstation.DISPLAY_NAME else workstation.KEY
          .join(', ')
      }
      {
        id              : "workstation_type"
        name            : App.t 'events.conditions.workstation_type'
        resizable       : true
        sortable        : true
        minWidth        : 150
        field           : "workstation_type"
        cssClass        : "event-cell"
        formatter       : (row, cell, value, columnDef, dataContext) ->
          headers = dataContext.get('headers')
          if headers
            headers = _.groupBy headers, 'NAME'
            if headers[columnDef.field] and headers[columnDef.field].length
              App.t "events.conditions.workstation_type_#{headers[columnDef.field][0].VALUE}"
      }
      {
        id        : "recipients"
        name      : App.t 'events.conditions.recipients_column'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "recipients"
        cssClass  : "event-cell"

        asyncPostRender: (cellNode, row, dataContext, colDef) ->
          participantView = Marionette.ItemView.extend
            behaviors:
              EntityInfo:
                targets       : '.popover_info'
                behaviorClass : App.Behaviors.Events.EntityInfo
            template: "events/recipients"
            serializeModel: (model) ->
              _.assign @model.toJSON(),
                without_title: true

          view = new participantView
            model: dataContext

          view.render()
          $(cellNode).empty().append view.$el

        formatter       : (row, cell, value, columnDef, dataContext) ->
          Marionette.Renderer.render "events/recipients", _.assign dataContext.toJSON(),
            without_title           : true
      }
      {
        id        : "policies"
        name      : App.t 'events.conditions.policies'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "policies"
        cssClass  : "event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          _.map dataContext.get(columnDef.field), (policy) ->
            if policy.DISPLAY_NAME then policy.DISPLAY_NAME else policy.KEY
          .join(', ')
      }
      {
        id        : "protected_documents"
        name      : App.t 'events.conditions.protected_documents'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "protected_documents"
        cssClass  : "event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          _.map dataContext.get(columnDef.field), (protected_document) ->
            protected_document.DISPLAY_NAME
          .join(', ')
      }
      {
        id        : "ATTACHMENT_COUNT"
        name      : App.t 'events.conditions.attachment_count'
        resizable : true
        sortable  : true
        minWidth  : 50
        field     : "ATTACHMENT_COUNT"
        cssClass  : "center event-cell"
      }
      {
        id        : "RULE_GROUP_TYPE"
        name      : App.t 'events.conditions.rule_group_type'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "RULE_GROUP_TYPE"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if dataContext.get(columnDef.field)
            App.t "events.conditions.rule_group_type_#{dataContext.get(columnDef.field).toLowerCase()}"
      }
      {
        id        : "lists"
        name      : App.t 'events.conditions.resource_column'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "lists"
        cssClass  : "event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          _.map(dataContext.get(columnDef.field), (list) -> list.DISPLAY_NAME).join(', ')
      }
      {
        id        : "tags"
        name      : App.t 'events.conditions.tags'
        resizable : true
        sortable  : true
        minWidth  : 200
        field     : "tags"
        cssClass  : "event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          tags_list = dataContext.get(columnDef.field)
          tags = "<ul style='display: inline;'>"

          tags += _.map tags_list, (tag) ->
            "<li style='display: inline;'>
              <span style='background-color:#{tag.COLOR}};padding-left: 14px;height: 16px;'></span>
              <span style='margin-left: 5px;'>#{tag.DISPLAY_NAME}</span>
            </li>"
          .join(', ')
          tags += "<ul>"

          return tags
      }
      {
        id        : "CAPTURE_DATE"
        name      : App.t 'events.conditions.capture_date_column'
        resizable : true
        sortable  : true
        minWidth  : 260
        field     : "CAPTURE_DATE"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          "#{moment.utc("#{dataContext.get(columnDef.field)}")
          .local().format('DD/MM/YYYY HH:mm:ss')}"
      }
      {
        id        : "OBJECT_SIZE"
        name      : App.t 'events.conditions.object_size'
        resizable : true
        sortable  : true
        minWidth  : 100
        field     : "OBJECT_SIZE"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          App.Helpers.getBytesWithUnit dataContext.get(columnDef.field)
      }
      {
        id        : "capture_server"
        name      : App.t 'events.conditions.capture_server_column'
        resizable : true
        sortable  : true
        minWidth  : 200
        field     : "capture_server"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if dataContext.get('CAPTURE_SERVER_HOSTNAME')
            if dataContext.get('CAPTURE_SERVER_IP')
              "#{dataContext.get('CAPTURE_SERVER_HOSTNAME')} (#{dataContext.get('CAPTURE_SERVER_IP')})"
            else
              "#{dataContext.get('CAPTURE_SERVER_HOSTNAME')}"
          else
            dataContext.get('CAPTURE_SERVER_IP')
      }
      {
        id        : "task_name"
        name      : App.t 'events.conditions.crawler_task_name_column'
        resizable : true
        sortable  : false
        minWidth  : 150
        field     : "task_name"
        cssClass  : "event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          dataContext.get('groupedHeaders')?[columnDef.field]?[0].VALUE
      }
      {
        id        : "create_date"
        name      : App.t 'events.conditions.crawler_create_date_column'
        resizable : true
        sortable  : false
        minWidth  : 260
        field     : "create_date"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if val = dataContext.get('groupedHeaders')?[columnDef.field]?[0].VALUE
            "#{moment.utc(val).local().format('DD/MM/YYYY HH:mm:ss')}"
      }
      {
        id        : "modify_date"
        name      : App.t 'events.conditions.crawler_modify_date_column'
        resizable : true
        sortable  : false
        minWidth  : 260
        field     : "modify_date"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if val = dataContext.get('groupedHeaders')?[columnDef.field]?[0].VALUE
            "#{moment.utc(val).local().format('DD/MM/YYYY HH:mm:ss')}"
      }
      {
        id        : "task_run_date"
        name      : App.t 'events.conditions.crawler_task_run_date_column'
        resizable : true
        sortable  : false
        minWidth  : 260
        field     : "task_run_date"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          if val = dataContext.get('groupedHeaders')?[columnDef.field]?[0].VALUE
            "#{moment.utc(val).local().format('DD/MM/YYYY HH:mm:ss')}"
      }
      {
        id        : "destination_type"
        name      : App.t 'events.conditions.destination_type'
        resizable : true
        sortable  : false
        minWidth  : 150
        field     : "destination_type"
        cssClass  : "center event-cell"

        formatter: (row, cell, value, columnDef, dataContext) ->
          val = dataContext.get('groupedHeaders')?[columnDef.field]?[0].VALUE
          locale = App.t 'events.conditions.destination_type_list', { returnObjectTrees: true }
          locale[val]
      }
      {
        id        : "DESTINATION_PATH"
        name      : App.t 'events.conditions.destination_path'
        resizable : true
        sortable  : true
        minWidth  : 150
        field     : "DESTINATION_PATH"
        cssClass  : "event-cell"
      }
    ]

  getSelected: ->
    @objects_table_.getSelectedModels()

  setColumns: ->
    col = []
    all_columns = _.groupBy @columns, 'id'
    selection = @collection.selection

    if selection
      columns = selection.get('QUERY').columns

      for column in columns when all_columns[column]
        col.push all_columns[column][0]

    return if col.length then col else @columns


  onShow: ->
    @collection.on 'reset', =>
      @objects_table_.grid.setColumns @setColumns()

    @objects_table_ = new App.Views.Controls.TableView
      collection: @collection
      config:
        default:
          enableColumnPicker: false
        loadColumns: false
        autosizeColumns: false
        columns: @setColumns()

    # Рендерим контролы
    @objects_table.show @objects_table_

    @listenTo @objects_table_, "table:select", (selected) ->
      if selected and selected.length is 1
        @trigger 'childview:objectSelected', selected[0]

    @listenTo @objects_table_, 'table:sort', _.bind(@collection.sortCollection, @collection)

    @listenTo App.Layouts.Application.content, "resize", (args) =>
      @objects_table_.resize(args.height - 160)

    @objects_table_.resize(App.Layouts.Application.content.$el.height() - 160)
