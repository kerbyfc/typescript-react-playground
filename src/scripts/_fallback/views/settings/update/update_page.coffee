"use strict"

require "jquery.fileupload"
Config = require "settings/config.json"
updateService = require "models/settings/update_service.coffee"
UpdateProgress = require "views/settings/update/update_progress.coffee"

configurationStates = {
  'unknown', 'ready', 'busy'
}

class UpdatePage extends Marionette.ItemView

  template: "settings/update/update_page"

  className: "update-page"

  ui:
    $uploadForm           : "form"
    $uploadFileName         : ".upload__file-name"
    $uploadBtnAdd         : ".upload__add"
    $uploadBtnCancel        : ".upload__cancel"
    $uploadProgress         : ".upload__progress"
    $uploadProgressBar        : ".upload__progress .progress-bar"
    $uploadProgressContainer    : ".upload__progress-container"

  events:
    "click [data-action=cancel]"  : "onClickCancel"
    "click [data-action=refresh]" : "onClickRefresh"

  initialize: ->
    @_configurationState = configurationStates.unknown

  onShow: ->
    @requestConfiguration()

  onClose: ->
    App.Configuration.hide()

  onDestroy: ->
    @xhr?.abort()

  onRender: ->
    @initUploadBtn()
    @ui.$uploadProgressContainer.hide()
    if @_configurationState is configurationStates.busy
      App.Configuration.show()
    else
      App.Configuration.hide()

  initUploadBtn: ->
    $uploadForm = @ui.$uploadForm
    $uploadForm.fileupload(

      url: updateService.UPLOAD_URL

      progressall: (e, data) =>
        progress = parseInt(data.loaded / data.total * 100, 10)
        @ui.$uploadProgress.addClass "_active"
        @ui.$uploadProgressBar.css "width", "#{progress}%"

      add: (e, data) =>
        @ui.$uploadProgress.removeClass "_active"
        @ui.$uploadProgressBar.css "width", 0

        @requestConfiguration().done( =>
          updateLimit = updateService.REQUIRED_DISK_FREE_SPACE + data.files[0].size

          if @serverDiskFreeSpace > updateLimit
            @onAddFile(data)
            xhr = @xhr = $uploadForm.fileupload("send", {
              disableNProgress: true
              files: data.files
            })
            xhr.error(@onError.bind(@))
            xhr.success(@onSuccess.bind(@))
            xhr.complete(@onComplete.bind(@))
          else
            @ui.$uploadFileName.html(@createErrorMsg(App.t "settings.update.msg__free-space"))
        )
    )

  onClickCancel: (e) ->
    e.preventDefault()
    @xhr.abort()

  onClickRefresh: ->
    @requestConfiguration()

  requestConfiguration: ->
    updateService.getDiskFreeSpace().done (diskFreeSpace) =>
      @serverDiskFreeSpace = diskFreeSpace

      lastConfigurationState = @_configurationState
      @_configurationState = if App.Configuration.isEdited() or App.Configuration.isLocked()
      then configurationStates.busy
      else configurationStates.ready

      if lastConfigurationState isnt @_configurationState
        @render()

  onAddFile: (data) ->
    @$el.addClass "_upload"
    @ui.$uploadProgressContainer.show().next(".upload__error-msg").remove()
    @ui.$uploadFileName.text(data.files[0].name)

  onError: (xhr, textStatus) ->
    if (textStatus is "abort")
      @onAbort.apply(@, arguments)
    else
      @ui.$uploadProgressContainer.after(@createErrorMsg(
        App.t("settings.update.msg__#{xhr.responseText}")
      ))

  onAbort: ->
    @$el.removeClass "_upload"
    @ui.$uploadProgressContainer.hide()

  onComplete: ->
    @$el.removeClass "_upload"
    @ui.$uploadProgress.removeClass "_active"

  onSuccess: ->
    App.modal.show(updateProgress = new UpdateProgress)
    App.Session.user.setUpdateOwner(true)
    @listenTo updateProgress, "error:update", (data) =>
      @ui.$uploadProgressContainer.after(@createErrorMsg(data["error"]))

  templateHelpers: =>
    configurationState: @_configurationState

  createErrorMsg: (msg) ->
    $("<div>").addClass("upload__error-msg").text(msg)

module.exports = UpdatePage
