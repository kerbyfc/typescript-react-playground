"use strict"

require "views/controls/grid.coffee"
helpers = require "common/helpers.coffee"

DeagnosticView = require "views/settings/diagnostic.coffee"
DiagnosticTask = require 'models/settings/diagnostic_task.coffee'

exports.ServicesEmpty = class Services extends Marionette.ItemView

  template: "settings/services/empty"

  className: "content"

exports.Services = class Services extends App.Views.Controls.ContentGrid

  ui: ->
    ui = super

    _.extend ui,
      start   : '[data-action="start"]'
      restart : '[data-action="restart"]'
      stop    : '[data-action="stop"]'

  events:
    'click @ui.start'   : 'onAction'
    'click @ui.restart' : 'onAction'
    'click @ui.stop'    : 'onAction'

  regions:
    diagnosticRegion: "[data-region='diagnostic']"

  onDestroy: ->
    if @timeout
      clearTimeout(@timeout)
      delete @timeout

  onAction: (e) ->
    e.preventDefault()

    action = @$(e.target).attr('data-action')

    @trigger action, @getSelectedModels(), action

  refresh: ->
    @collection.fetch
      disableNProgress: true
      wait: true
      error: ->
        App.Notifier.showError
          title: App.t 'settings.services_tab'
          text: App.t "settings.services.services_refresh_failed"
          hide: true

  onShow: ->
    super
    @listenTo @, "table:select", @updateToolbar
    @timeout = setInterval @refresh.bind(@), 30000

    if helpers.can(key: "settings/services:diagnostic:execute")
      @diagnosticRegion.show new DeagnosticView
        collection: new DiagnosticTask.collection

  getTemplate: -> "settings/services/services"

  blockToolbar: ->
    @ui.start.prop 'disabled', true
    @ui.restart.prop 'disabled', true
    @ui.stop.prop 'disabled', true

  updateToolbar: ->
    selected = @getSelectedModels()

    @blockToolbar()

    if selected.length and helpers.can({type: 'service', action: 'edit'})
      @ui.start.prop "disabled", false
      @ui.restart.prop "disabled", false
      @ui.stop.prop "disabled", false
