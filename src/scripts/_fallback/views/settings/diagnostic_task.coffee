"use strict"

module.exports = class DiagnosticTaskItem extends Marionette.ItemView

  template: "settings/diagnostic_task"

  ui:
    status     : "[data-ui='status']"
    file       : "[data-ui='file']"
    progress   : "[data-ui='progress']"
    complete   : "[data-ui='complete']"
    percentage : "[data-ui='percentage']"

  events:
    "click [data-action=cancel]": "_cancel"

  modelEvents:
    "all": "update"

  onShow: ->
    @update()

  _cancel: (e) ->
    e.preventDefault()
    @model.stop()

  toggle: (element, condition) ->
    @ui[element]?.toggleClass "_hidden", not condition

  update: =>
    @toggle "message", @model.hasFile()

    @ui.status.html @model.getStatusText()
    @toggle "status", not _.isEmpty @model.getStatusText()

    file = @model.get "file"
    @toggle "complete", file
    @ui.file
      .html @model.getFileName()
      .attr "href", file

    @toggle "progress", @model.isInProgress()
    @ui.percentage.html @model.get("progress") + "%"
