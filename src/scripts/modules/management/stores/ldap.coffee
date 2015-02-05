Store  = require "core/store"

class LdapStore extends Store

  value = 0

  data = lol: true

  @on 'init', (val) ->
    value = val

  @on 'console', (val) ->
    false

  value: ->
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
