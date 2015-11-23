"use strict"

exports.EmptyPluginInfo = class EmptyPluginInfo extends Marionette.ItemView

  template: 'settings/plugins/empty_plugins'

  className : "content"

exports.PluginInfo = class PluginInfo extends Marionette.LayoutView

  # ****************
  #  MARIONETTE
  # ****************
  modelEvents :
    "change" : -> @render()

  regions :
    tokens : "#tokens_tab"

  templateHelpers : ->
    object_type_codes   : _.groupBy App.request('bookworm', 'event').toJSON(), 'mnemo'
    protocols           : _.groupBy App.request('bookworm', 'protocol').toJSON(), 'mnemo'
    is_event_licensed   : @model.is_event_licensed

    is_license_active   : (license) ->
      moment()
      .isBefore if 1
        moment license.issue_date
        .add "days", license.active_days

    license_issue       : (license) ->
      moment license.issue_date
      .format "LL"

    license_end         : (license) ->
      if _.gt if 1
        moment license.issue_date
        .add "days", license.active_days
        .diff moment(), "days"
      ,
        1824
      then App.t "settings.license.unlimited_license"
      else
        moment license.issue_date
        .add "days", license.active_days
        .format "LL"

  template : "settings/plugins/plugin_info"

  className : "content"

  onShow: ->
    @tokens.show @options.tokensView
