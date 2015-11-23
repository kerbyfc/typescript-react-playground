"use strict"

module.exports = class App.Views.Dashboards.CreateDialog extends Marionette.ItemView

  template: "dashboards/dialogs/create_dashboard"

  events:
    "click [data-action='save']" : "save"

  ui:
    "name"          : "input[name='DISPLAY_NAME']"

  templateHelpers: ->
    modal_dialog_title: @options.title

  hideErrorHint: (attr) ->
    if @ui[attr].data("bs.popover")
      @ui[attr].popover("destroy")

  showErrorHint: (attr, error) ->
    @hideErrorHint(attr)

    position = @ui[attr].data("tooltip-position") or "right"

    @ui[attr].popover(
      placement: position
      trigger: "manual"
      content: error
      container: @ui[attr].closest("[data-error-container]")
    )
    @ui[attr].popover('show')

  save: (e) ->
    e?.preventDefault()

    # Собираем данные с контролов
    data = Backbone.Syphon.serialize(@)

    @options.callback(data)

  onDestroy: ->
    Backbone.Validation.unbind(@)

  onShow: ->
    Backbone.Validation.bind(@)
