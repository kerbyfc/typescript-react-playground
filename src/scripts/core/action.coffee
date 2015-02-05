###*
* Creates an unique action for a name.
* The action can then be used to dispatch a payload.
*
* Ex:
* var ClickThread = Action('clickThread'); // Create the action once
* ClickThread(id); // Dispatch a payload any number of times
*
###

Action = (name) ->

  dispatch = (payload) ->
    dispatcher.dispatch name, payload
    return

  invariant !names[name], 'An action with the name %s was already created', name
  names[name] = name

  dispatch.toString = ->
    name

  dispatch

'use strict'
invariant = require('./invariant')
dispatcher = require('./dispatcher')
names = {}

###*
* Creates one or more actions, exposed by name in an object (useful to assign to module.exports)
* var actions = Action.create('clickThread', 'scroll');
###

Action.create = (args...) ->

  # array passed?
  if _.isArray args[0]
    args = args[0]

  _.reduce args, (obj, name) ->
    obj[name] = Action(name)
    obj
  , {}

module.exports = Action
