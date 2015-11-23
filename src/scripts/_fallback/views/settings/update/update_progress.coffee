"use strict"

require "pushstream"
updateService = require "models/settings/update_service.coffee"
UpdateChangeLog = require "views/settings/update/update_change_log.coffee"

class UpdateProgress extends Marionette.ItemView

  template: "settings/update/update_progress"

  ui:
    $updateProgress         : ".update__progress"
    $uploadProgressBar      : ".upload__progress .progress-bar"
    $currentStage           : ".update__stage"

  disableModalClose: true

  initialize: ->
    updateSocket = updateService.startListeningProgressUpdateChannel()
    updateSocket.onstatuschange = (status) =>
      if status is PushStream.OPEN
        updateSocket.wrapper.connection.onmessage = @onMessageServiceUpdate.bind @
    updateSocket.connect()

    App.Session.deinitIdler()

    @waiting = true

  onDestroy: ->
    App.Session.initIdler()
    updateService.stopListeningProgressUpdateChannel()

  onFirstMessage: ->
    @waiting = false
    @ui.$updateProgress
    .removeClass("_waiting")
    .addClass("_active")

  onMessageServiceUpdate: (msg) ->
    try
      return if not data = JSON.parse(msg.data)
      @onFirstMessage() if @waiting
      @updateProgress(data["data"] or data)

  updateProgress: (data) ->
    percents = data["percents"]
    stage = data["stage"]

    @triggerMethod(stage + ":update", data)
    @ui.$uploadProgressBar.css "width", "#{percents}%"
    @ui.$currentStage.text(App.t("settings.update.msg__#{stage}"))

  onFinishedUpdate: ->
    @ui.$updateProgress.removeClass "_active"
    updateService.getVersion().done (data) ->
      App.modal.show(new UpdateChangeLog(data.data))

  onErrorUpdate: ->
    @destroy()
    App.Session.user.setUpdateOwner(false)

module.exports = UpdateProgress
