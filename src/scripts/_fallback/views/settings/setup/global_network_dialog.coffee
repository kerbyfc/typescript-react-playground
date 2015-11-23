"use strict"

module.exports = class GlobalNetworkDialog extends Marionette.ItemView

  template: "settings/setup/network/global_network_dialog"

  events:
    "click [data-action='save']": "save"

  templateHelpers: ->
    title: @options.title

  behaviors: ->
    data = @options.model.toJSON()

    ['dns_servers', 'dns_suffix', 'ntp_servers'].forEach (attr) ->
      data[attr] = data[attr].join('\n')

    Form:
      listen: @options.model
      syphon: data

  save: (e) ->
    e.preventDefault()
    @options.callback @getData()
