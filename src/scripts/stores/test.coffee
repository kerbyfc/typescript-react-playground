# class TestStore extends Store

#   value = 0

#   data = lol: false

#   @on 'init', (val) ->
#     value = val

#   @on 'test', (vals...) ->
#     console.debug vals

#   @on 'console', (val) ->
#     console.log val

#   value: ->
#     value

module.exports = {}
