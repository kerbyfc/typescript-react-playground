"use strict"

require "behaviors/common/lazy_load.coffee"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Views.AuditEvents ?= {}

    class App.Views.AuditEvents.ContentItem extends Marionette.ItemView

      template: "settings/audit_events/content_item"

      templateHelpers: ->
        CHANGE_DATE:
          moment.utc @model.get "CHANGE_DATE", App.Config.dateTimeFormat
          .local().format "L LT"
        ENTITY_DISPLAY_NAME:
          @model.get "ENTITY_DISPLAY_NAME"  or  App.t "global.unknown"
        ENTITY_TYPE:
          App.t "settings.audit_events_entities.#{@model.get "ENTITY_TYPE"}"
        OPERATION:
          App.t "settings.audit_events_operations.#{@model.get "OPERATION"}"
        USER_NAME:
          AuditEvents.reqres.request "get:user:name:by:id", @model.get "USER_ID"
        PROPERTY_CHANGES:
          @model.get "PROPERTY_CHANGES"
        baseKey:
          @model.getBaseKey()
        gridHeaders:
          @getGridHeaders()
        renderRow:
          @renderRow

      triggers:
        "click @ui.toggle_more_info" : "toggle:more:info"

      ui:
        more_info         : "[data-more-info]"
        toggle_more_info  : "[data-toggle-more-info]"

      className: "audit_event"

      onToggleMoreInfo: ->
        @ui.more_info.prop "hidden",
          not @ui.more_info.prop("hidden")

      ##########################################################################
      # PUBLIC

      ###*
       * Maps grid headers to their locale keys
       * @result {Array} Locale keys
      ###
      getGridHeaders: ->
        headerLocales =
          "new"     : "configuration.new_value"
          "old"     : "configuration.old_value"
          "request" :      "organization.value"

        headers = ["configuration.entity"]

        for own key of @model.get "PROPERTY_CHANGES"
          headers.push headerLocales[key]

        headers

      ###*
       * Renders row template, passes data to it
       * @param {String} rowKey - change property key
       * @result {String} row template
      ###
      renderRow: (rowKey) =>
        row =
          key   : rowKey
          cells : @model.getChangedVals rowKey

        Marionette
        .Renderer
        .render "settings/audit_events/partials/content_item_row", row



    class App.Views.AuditEvents.ContentEmpty extends Marionette.ItemView

      template: "settings/audit_events/content_empty"



    class App.Views.AuditEvents.Content extends Marionette.CompositeView

      # *************
      #  PRIVATE
      # *************
      _generate_timestamp = (date) ->
        moment.utc date, "YYYY-MM-DD HH:mm:ss.SSS"
        .unix()

      _get_sort_options = ->
        $sort_param = @ui.sort_params.filter ":checked"
        result = {}

        result[$sort_param.data "sort-param"] = $sort_param.data "sort-order"
        result

      _maybe_scroll_top = (collection, resp, opts) ->
        if opts.reset
          @ui.lazy_load.scrollTop 0


      # **********
      #  INIT
      # **********
      initialize: ->
        @listenTo AuditEvents,
          "maybe:init:fetch:audit:events"
          _.after 2, -> AuditEvents.trigger "fetch:audit:events"

        AuditEvents.reqres.setHandler "get:sort:options",
          _get_sort_options
          @


      # ****************
      #  BEHAVIOURS
      # ****************
      behaviors:
        "lazy_load":
          behaviorClass : App.Behaviors.Common.LazyLoad
          callback: ->
            AuditEvents.trigger "fetch:audit:events",
              data:
                filter:
                  if AuditEvents.reqres.request("get:sort:options").CHANGE_DATE is "desc"
                    CHANGE_DATE_END:
                      _generate_timestamp @collection.first().get "CHANGE_DATE"
                  else
                    {}
                start: @collection.length
              remove: false
          cancel_callback:
            _.throttle ->
              if @collection.length
                App.Notifier.showSuccess
                  text: App.t "global.all_loaded",
                    entities:
                      App.t "settings.audit_events"
                      .toLowerCase()
            ,
              PNotify.prototype.options.delay
            ,
              trailing: false


      # **************
      #  BACKBONE
      # **************
      className: "content"


      # ****************
      #  MARIONETTE
      # ****************
      template            : "settings/audit_events/content"

      emptyView           : App.Views.AuditEvents.ContentEmpty

      childView           : App.Views.AuditEvents.ContentItem

      childViewContainer  : "#audit_events_content_table"

      collectionEvents:
        sync: _maybe_scroll_top

      ui:
        lazy_load           : "[data-lazy-load]"
        sort_params         : "[data-sort-param]"
        sort_order_showers  : "[data-sort-order-show]"

      triggers:
        "click @ui.sort_params":
          event           : "maybe:change:order"
          preventDefault  : false


      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onShow: ->
        AuditEvents.trigger "maybe:init:fetch:audit:events"

      onDestroy: ->
        @collection.stopListening()

      onMaybeChangeOrder: ->
        $sort_param = @ui.sort_params.filter ":checked"

        if $sort_param.data("sort-order") is "asc"
          $sort_param.data "sort-order", "desc"
          $sort_param
          .siblings "[data-sort-order-show]"
          .addClass "sorting__sort_bt"

        else if $sort_param.data("sort-order") is "desc"
          $sort_param.data "sort-order", "asc"
          $sort_param
          .siblings "[data-sort-order-show]"
          .removeClass "sorting__sort_bt"

        AuditEvents.trigger "fetch:audit:events",
          data:
            start : 0
            limit : @collection.length
          reset: true
