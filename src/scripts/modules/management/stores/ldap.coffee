Store  = require "core/store"
Action = require "core/action"

actions = Action.create [
]

class LdapStore extends Store

  actions: [
    'init'
    'increment'
    'decrement'
  ]

  value = 0

  @on 'init', (val) ->
    value = val

  value: ->
    console.log value
    value


module.exports = new LdapStore

#   var value = 0;

#   on(init, function(val) {
#     value = val;
#   });

#   on(decrement, function(offset) {
#     value -= offset;
#   });

#   on(increment, function(offset) {
#     value += offset;
#   });

#   return {
#     value: function() { return value }
#     actions: actions
#   };
# });
