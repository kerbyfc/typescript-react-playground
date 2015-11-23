"use strict"

module.exports = class DiagnosticTaskCreator extends Marionette.ItemView

  template: "settings/dialogs/diagnostic"

  ui:
    form  : "form"
    start : "[data-action='start']"

  events:
    "click @ui.start": "_start"

  initialize: (options = {}) ->
    { @collection } = options

  _start: (e) ->
    e.preventDefault()

    params = _.reduce(@ui.form.serializeArray(), (res, val) ->
      res[val.name] = (val.value is "true")
      return res
    , {})

    @collection.start(params)
      .done =>
        @destroy()
        @options.done?()

      .fail =>
        @options.fail?()
        App.Notifier.showError
          title : App.t "settings.diagnostic.pnotify.run"
          text  : App.t "settings.diagnostic.pnotify.run_failed"
