'use strict'
Signal = require('signals').Signal
invariant = require('core/invariant')
# Singleton dispatcher used to broadcast payloads to stores.# Ensures the application state stored in the stores is updated predictably.
#

dispatcher = do ->
  dispatching = false
  storeId = 0
  stores = {}
  isPending = {}
  isHandled = {}
  currentAction = null
  currentPayload = null
  started = new Signal
  stopped = new Signal

  register = (store) ->
    stores[storeId] = store
    store._id = storeId
    storeId+=1
    return

  unregister = (store) ->
    invariant stores[store._id], 'Dispatcher.unregister(...): `%s` does not map to a registered store.', store
    delete stores[store._id]
    return

  waitFor = ->
    storeDeps = arguments
    invariant dispatching, 'dispatcher.waitFor(...): Must be invoked while dispatching.'
    i = 0
    while i < storeDeps.length
      store = storeDeps[i]
      id = store._id
      if isPending[id]
        invariant isHandled[id], 'dispatcher.waitFor(...): Circular dependency detected while ' + 'waiting for `%s`.', id
        i+=1
        continue
      invariant stores[id], 'dispatcher.waitFor(...): `%s` does not map to a registered store.', id
      notifyStore id
      i+=1
    return

  dispatch = (actionName, payload) ->
    invariant !dispatching, 'dispatch.dispatch(...): Cannot dispatch in the middle of a dispatch.'
    currentAction = actionName
    currentPayload = payload
    startDispatching()
    try
      for id of stores
        if isPending[id]
          i+=1
          continue
        notifyStore id
    finally
      stopDispatching()
    return

  startDispatching = ->
    dispatching = true
    for id of stores
      isPending[id] = false
      isHandled[id] = false
    started.dispatch()
    return

  stopDispatching = ->
    currentAction = currentPayload = null
    dispatching = false
    stopped.dispatch()
    return

  notifyStore = (id) ->
    isPending[id] = true
    stores[id]._handleAction currentAction, currentPayload
    isHandled[id] = true
    return

  {
    register: register
    unregister: unregister
    waitFor: waitFor
    dispatch: dispatch
    started: started
    stopped: stopped
  }
module.exports = dispatcher
