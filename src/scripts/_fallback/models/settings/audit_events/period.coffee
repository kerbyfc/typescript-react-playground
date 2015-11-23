"use strict"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Models.AuditEvents ?= {}

    class App.Models.AuditEvents.Period extends App.Common.ValidationModel

      url: "#{App.Config.server}/api/setting"

      isNew: -> false

      validation:
        audit_period:
          min     : 0
          pattern : "digits"

      initialize: ->
        @fetch()
        @listenToOnce @, "sync", =>
          @listenTo @,
            "change:audit_period",
            _.throttle(@_updatePeriod, 1000, leading: false)

      ##########################################################################
      # PRIVATE

      _updatePeriod: =>
        @save null,
          data:
            JSON.stringify
              audit_period: @get "audit_period"
          success: @_notifyPeriod

      _notifyPeriod: =>
        period = @get "audit_period"

        App.Notifier.showSuccess
          text: App.t @_getPeriodMessage(period),
            days: period

      _getPeriodMessage: (period) ->
        res = "settings.audit_events_period_saved"

        switch
          when parseInt(period.slice(-2), 10) in [11, 12, 13, 14]
            res += "_5_to_0"

          when parseInt(period.slice(-1), 10) is 1
            res += "_1"

          when parseInt(period.slice(-1), 10) in [2, 3, 4]
            res += "_2_to_4"

          else res += "_5_to_0"
