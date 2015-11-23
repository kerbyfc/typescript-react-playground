"use strict"

class UpdateChangeLog extends Marionette.ItemView

  template: "settings/update/update_change_log"

  disableModalClose: true

  events:
    "click [data-action=reload]": "onClickReload"

  initialize: (data) ->
    @data = data

  serializeData: ->
    @data

  onClickReload: (e) ->
    e.preventDefault()
    window.location.reload()

module.exports = UpdateChangeLog
