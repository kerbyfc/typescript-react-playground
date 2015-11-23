"use strict"

module.exports = class EthDialog extends Marionette.ItemView

  template: "settings/setup/network/eth_dialog"

  events:
    "click [data-action='save']": "save"

  templateHelpers: ->
    title: @options.title

  behaviors: ->
    data = {}

    data = @options.model.toJSON()

    Form:
      listen : @options.model
      syphon : data

  ui:
    dhcp: '#bootproto'
    may_disabled : "[data-may-disabled]"

  onShow: ->
    if @model.get 'bootproto'
      @ui.may_disabled.prop('disabled', true)

    @ui.dhcp.on 'change', (e) =>
      if $(e.currentTarget).prop('checked')
        @ui.may_disabled.prop('disabled', true)
      else
        @ui.may_disabled.prop('disabled', false)

  onDestroy: ->
    @options.close()

  save: (e) ->
    e.preventDefault()

    data = @getData()

    @options.callback data
