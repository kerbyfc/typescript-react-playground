"use strict"

require "backbone.stickit"
require "behaviors/common/role.coffee"
helpers = require "common/helpers.coffee"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Views.AuditEvents ?= {}

    class App.Views.AuditEvents.Period extends Marionette.ItemView

      behaviors: ->
        Role: [
          action   : "remove"
          elements : [@ui.audit_period_save]
          islock   : -> _not_edit_duration()
        ,
          action   : "disabled"
          elements : [@ui.audit_period]
          islock   : -> _not_edit_duration()
        ]

      bindings:
        "[name=audit_period]": "audit_period"

      className: "form__block styled"

      template: "settings/audit_events/period"

      ui:
        audit_period        : "[name=audit_period]"
        audit_period_save   : "[data-period-save]"

      events:
        'keypress @ui.audit_period':'onTypePeriod'

      initialize: ->
        @listenTo @model, 'request', @_lock_field
        @listenTo @model, 'sync', @_unlock_field

      onShow: ->
        Backbone.Validation.bind @
        @stickit()

      onDestroy: ->
        Backbone.Validation.unbind @

      onTypePeriod: (e) ->
        # Prevent user from entering decimal point
        if e.which is 46 then e.preventDefault()

      ##########################################################################
      # PRIVATE

      _lock_field: =>
        @ui.audit_period.attr
          "data-search-loading" : ""
          "disabled"            : ""

      _unlock_field: =>
        @ui.audit_period.removeAttr 'data-search-loading disabled'

      _not_edit_duration = ->
        not helpers.can({action: "edit_duration", type: "audit_event"})
