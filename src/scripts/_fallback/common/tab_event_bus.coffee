storage = require 'local-storage'

class TabEventBus

  storageKey: 'tabev_message'

  constructor: ->
    storage.on @storageKey, _.bind(@_storageHandler, @)

  send: (channel, data) ->
    message =
      channel: channel
      message: data
      random: Math.random()

    storage(@storageKey, message)

  _storageHandler: (data) ->
    @trigger data.channel, data.message

_.extend TabEventBus::, Backbone.Events

module.exports = new TabEventBus
