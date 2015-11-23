"use strict"

require "bootstrap.daterangepicker"
require "models/settings/audit_events/period.coffee"
require "views/settings/audit_events/period.coffee"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Views.AuditEvents ?= {}

    class App.Views.AuditEvents.UserFilter extends Marionette.ItemView

      className: 'sidebar__content'

      # ****************
      #  MARIONETTE
      # ****************
      template : "settings/audit_events/user_filter"


      # **************
      #  BACKBONE
      # **************
      tagName   : "option"

      attributes : ->
        value : @model.id



    class App.Views.AuditEvents.Filters extends Marionette.CompositeView

      # *************
      #  PRIVATE
      # *************
      _init_daterangepicker = (self) ->
        self.ui.date.daterangepicker
          format : "DD.MM.YYYY"
          locale : App.t "daterangepicker", returnObjectTrees : true
          opens  : "left"

      _init_regions = (self) ->
        self.rm = new Marionette.RegionManager()
        self.rm.addRegions self.regions
        self.rm.get "period"
        .show new App.Views.AuditEvents.Period(
          model : new App.Models.AuditEvents.Period
        )

      _generate_timestamp = (self, flag) ->
        moment self.ui.date.val().split("-")[flag], "DD.MM.YYYY"
        .add "days", flag
        .subtract "seconds", flag
        .unix()

      _get_fetch_filters = ->
        _.omit
          CHANGE_DATE_START :
            @ui.date.data("val")  or  _generate_timestamp @, 0
          CHANGE_DATE_END   :
            @ui.date.data("val")  or  _generate_timestamp @, 1
          ENTITY_TYPE     : @ui.entity.val()
          OPERATION     : @ui.operation.val()
          USER_ID       : @ui.user.val()
        ,
          (val) ->
            if val is "<all>"
              true


      # *************
      #  PUBLIC
      # *************
      render_without_root : true


      # **********
      #  INIT
      # **********
      initialize : ->
        AuditEvents.reqres.setHandler "get:fetch:filters",
          _get_fetch_filters
          @

        @listenToOnce App.Routes.Application, "route", ->
          @listenToOnce App.Routes.Application, "route", @destroy


      # ****************
      #  MARIONETTE
      # ****************
      template      : "settings/audit_events/filters"

      childView       : App.Views.AuditEvents.UserFilter

      childViewContainer : "@ui.user"

      regions :
        "period" : "[data-audit-events-period]"

      ui:
        date     : "#audit_events_date_filter"
        date_clear : "#audit_events_date_filter_clear"
        entity     : "#audit_events_entity_filter"
        operation  : "#audit_events_operation_filter"
        user     : "#audit_events_users_filter"

      triggers :
        "apply.daterangepicker  @ui.date" : "show:clear:date"
        "click  @ui.date_clear"       : "clear:date"

        "apply.daterangepicker @ui.date"  : "change:filter"
        "click @ui.date_clear"        : "change:filter"
        "change @ui.entity"         : "change:filter"
        "change @ui.operation"        : "change:filter"
        "change @ui.user"         : "change:filter"

      templateHelpers : ->
        sort_filter_params : (locale) ->
          _ App.t locale, returnObjectTrees : true
          .pairs()
          .sort (p1, p2) ->
            if p1[1].toLowerCase() < p2[1].toLowerCase()
              -1
            else
              1
          .map (key_val) ->
            """
              <option value="#{ key_val[0] }">
                #{ key_val[1] }
              </option>
            """
          .value()


      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onShow : ->
        @collection.fetch
          silent  : true
          success : =>
            @collection.add_filter_all_users()
            @render()
            _init_regions @
            _init_daterangepicker @
            AuditEvents.trigger "maybe:init:fetch:audit:events"

      onDestroy : ->
        @rm.destroy()
        @ui.date.data "daterangepicker"
        .remove()

      onChangeFilter : ->
        AuditEvents.trigger "fetch:audit:events",
          data  :
            start : 0
          reset : true

      onShowClearDate : ->
        @ui.date_clear.prop "hidden", false
        @ui.date.data "val", false

      onClearDate : ->
        @ui.date_clear.prop "hidden", true
        @ui.date
          .val ""
          .data "val", "<all>"
