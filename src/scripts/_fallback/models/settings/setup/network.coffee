"use strict"

class NetworkInterface extends App.Common.ValidationModel

  validation:
    ipaddr:
      fn: (value, attr, computedState) ->
        if computedState.bootproto is 0
          return App.t 'settings.network.validate__ipaddr_required' if value is null or value is ''

          unless App.Helpers.patterns.ip.test value
            return App.t 'settings.network.validate__ipaddr'
    netmask:
      fn: (value, attr, computedState) ->
        if computedState.bootproto is 0
          return App.t 'settings.network.validate__netmask_required' if value is null or value is ''

          unless App.Helpers.patterns.netmask.test value
            return App.t 'settings.network.validate__netmask'
    gateway:
      fn: (value, attr, computedState) ->
        if computedState.bootproto is 0
          unless App.Helpers.patterns.ip
            App.t 'settings.network.validate__gateway'
    # dns_suffix: [
    #   pattern: /^[a-zA-Zа-яА-Я0-9_\\-\\.]*$/
    #   msg: 'not valid suffix'
    # ]

  islock: (data) ->
    if _.isString data
      data =
        type: 'network'
        action: data
    else
      data['type'] = 'network'

    super data

class NetworkInterfaces extends Backbone.Collection

  # **************
  #  BACKBONE
  # **************
  model : NetworkInterface


exports.Model = class Network extends App.Common.ValidationModel

  validation:
    ntp_servers:
      fn: (value) ->
        isValid = true
        valueItems = _.compact value.split '\n'
        valueItems.forEach (valueItem) ->
          isValid = false unless App.Helpers.patterns.ip.test valueItem

        App.t 'settings.network.validate__dns-servers' unless isValid

    dns_servers:
      fn: (value) ->
        isValid = true
        valueItems = _.compact value.split '\n'
        valueItems.forEach (valueItem) ->
          isValid = false unless App.Helpers.patterns.ip.test valueItem

        App.t 'settings.network.validate__dns-servers' unless isValid

    dns_suffix:
      fn: (value) ->
        isValid = true
        valueItems = _.compact value.split '\n'
        valueItems.forEach (valueItem) ->
          isValid = false unless App.Helpers.patterns.dns.test valueItem

        App.t 'settings.network.validate__dns-suffix' unless isValid

  islock: (data) ->
    if _.isString data
      data =
        type: 'network'
        action: data
    else
      data['type'] = 'network'

    super data

  # **************
  #  BACKBONE
  # **************
  urlRoot: "#{App.Config.server}/api/agent/network"

  # *************
  #  PRIVATE
  # *************
  _update_internal_collection = ->
    @networks_collection.reset @get "ifsettings"


  # ************
  #  PUBLIC
  # ************
  networks_collection: null

  save_settings: ->
    @set "ifsettings", @networks_collection.toJSON()
    @save()

  # **********
  #  INIT
  # **********
  initialize: ->
    @networks_collection = new NetworkInterfaces

    @on "change:ifsettings", _update_internal_collection
