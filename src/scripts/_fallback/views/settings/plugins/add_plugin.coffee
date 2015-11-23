"use strict"


class AddPluginInfo extends Marionette.ItemView

  template: 'settings/plugins/add_plugin_info'

  templateHelpers: ->
    object_type_codes   : _.groupBy App.request('bookworm', 'event').toJSON(), 'mnemo'
    protocols           : _.groupBy App.request('bookworm', 'protocol').toJSON(), 'mnemo'
    is_event_licensed   : @model.is_event_licensed

module.exports = class AddPluginView extends Marionette.LayoutView

  template: 'settings/plugins/add_plugin'

  templateHelpers: ->
    title: @options.title

  ui:
    upload          : "[data-elem='upload']"
    install_plugin  : "[data-action='install_plugin']"
    upload_plugin   : "[data-action='upload_plugin']"

  regions:
    plugin_info  : '[data-region="plugin_info"]'

  events:
    "change [data-action='upload_plugin']"  : 'showPluginInfo'
    "click [data-action='install_plugin']"  : 'installPlugin'

  installPlugin: (e) ->
    e.preventDefault()

    file = _.first @ui.upload_plugin[0].files

    @options.callback?(file)

  showPluginInfo: ->
    file = _.first @ui.upload_plugin[0].files

    @model.checkArchive(file).then (resp) =>
      @model.set resp.data

      @plugin_info.show new AddPluginInfo
        model: @model

      @ui.install_plugin.show()
      @ui.upload.hide()

  onShow: ->
    @ui.install_plugin.hide()
