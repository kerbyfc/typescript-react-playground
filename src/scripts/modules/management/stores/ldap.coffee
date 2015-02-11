# class LdapStore extends Store

#   value = 0

#   data = lol: true

#   @on 'init', (val) ->
#     value = val

#   @on 'console', (val) ->
#     console.log val

#   value: ->
#     value


Store     = require('core/stores/base')
actions   = require('./actions')

init      = actions.init
decrement = actions.decrement
increment = actions.increment

# module.exports = new LdapStore
module.exports = Store (listen, waitFor) ->
  value = 0

  listen init, (val) ->
    value = val

  listen decrement, (offset) ->
    console.log value
    value -= offset

  listen increment, (offset) ->
    value += offset

  value: ->
    value

  actions: actions

# ---
# generated by js2coffee 2.0.0