Signals    = require "signals"
Action = require "core/action"
dispatcher = require "core/dispatcher"

Signal = Signals.Signal

class Store

  # all stores
  instancies = {}

  @getInstance = ->
    instance = instancies[@name] ?= (new @)

  @on = (action, handler) ->
    i = @getInstance()
    i.constructor.handlers[action] = handler
    i.actions[action] = Action action

  @dependOn = (stores...) ->
    @instance().dependencies = stores

  constructor: ->

    # realize singleton
    if _.has instancies, @constructor.name
      return instancies[@constructor.name]

    @constructor::actions = {}

    @initialize.apply @constructor
    @

  initialize: ->
    @handlers     = {}
    @dependencies = []
    @changed      = new Signal

    @register = ->
        dispatcher.register @constructor

    @unregister = ->
        dispatcher.unregister @constructor

    @_handleAction = (actionName, payload) ->

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

    @register()

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
