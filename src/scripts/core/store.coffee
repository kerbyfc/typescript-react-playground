Signals    = require "signals"
dispatcher = require "core/dispatcher"

Signal = Signals.Signal

class Store

  # all stores
  instancies = {}

  Factory: @::constructor

  @instance: ->
    instancies[@name] ?= new @

  @on = (action, handler) ->
    @instance().handlers[action] = handler

  @dependOn = (stores...) ->
    @instance().dependencies = stores

  constructor: ->

    # TODO extend constructor
    @actions      = {}
    @handlers     = {}
    @dependencies = []

    @waitFor      = undefined
    @changed      = new Signal

    @name = @constructor.name

    @register()

  register: ->
    dispatcher.register @

  unregister: ->
    dispatcher.unregister @

  _handleAction: (actionName, payload) ->

    handler = undefined
    result = undefined

    # If this store subscribed to that action
    if actionName in @handlers
      handler = @handlers[actionName]
      # handlers are optional

      if handler
        dispatcher.waitFor.apply null, dependencies
        result = handler(payload)

      if result != false
        @changed.dispatch()

  @onChange = ->

    stores = arguments
    # curried, to separate the stores from the callback.
    (callback) ->
      count = 0

      inc = ->
        count += 1

      started = ->
        count = 0

      stopped = ->
        if count
          callback()

      i = 0
      while i < stores.length
        stores[i].changed.add inc
        i++
      dispatcher.started.add started
      dispatcher.stopped.add stopped

      ->
        dispatcher.started.remove started
        dispatcher.stopped.remove stopped
        i = 0
        while i < stores.length
          stores[i].changed.remove inc
          i++

module.exports = Store
