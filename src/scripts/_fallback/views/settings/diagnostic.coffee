"use strict"

config = require('settings/config.json').diagnostic.config

DiagnosticTaskView = require 'views/settings/diagnostic_task.coffee'
CreateTaskDialog   = require 'views/settings/dialogs/create_diagnostic_task.coffee'

module.exports = class DiagnosticView extends Marionette.CompositeView

  template: "settings/diagnostic"

  childView: DiagnosticTaskView

  childViewContainer: "[data-block=loop]"

  ui:
    start  : "[data-action='diagnose']"
    cancel : "[data-action='cancel']"

  events:
    "click @ui.start": "_createDiagnosticTask"
    "click @ui.cancel": "_cancel"

  collectionEvents:
    "all": "updateDiagnosticState"

  initialize: (options = {}) ->
    { @collection } = options
    @collection.fetch()

  _createDiagnosticTask: (e) ->
    e.preventDefault()
    App.modal.show new CreateTaskDialog
      collection: @collection
      done: @updateDiagnosticState

  _cancel: (e) ->
    e.preventDefault()
    @collection.at(0).stop()

  updateDiagnosticState: =>
    inProgress = @collection.hasProgress()
    @ui.start.toggle? not inProgress
    @ui.cancel.toggle? inProgress
