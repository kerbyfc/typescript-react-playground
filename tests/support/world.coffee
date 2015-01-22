module.exports = ->
  @World = World = (callback) ->

    @date = new Date()

    @utc = (callback) ->
      @date.toUTCString()

    callback()
