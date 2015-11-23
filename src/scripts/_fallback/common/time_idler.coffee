class TimeIdler

  defaults:
    timeout: 1800000
    throttleTime: 1000
    events: [
      'mousemove'
      'mousedown'
      'keypress'
      'DOMMouseScroll'
      'mousewheel'
      'touchmove'
      'MSPointerMove'
    ]

  constructor: (options = {}) ->
    @options = _.extend {}, @defaults, options
    @_handler = null

  # === Timer control ===

  start: ->
    @_init()
    @trigger 'start'
    @_start()

  stop: ->
    @_deinit()
    @trigger 'stop'
    @_stop()

  reset: ->
    @trigger 'reset'
    @_reset()

  # === PRIVATE ===

  _init: ->
    @_handler = _.throttle =>
      if @timer
        @trigger('user_event')
        @_reset()
    , @options.throttleTime

    _.each @options.events, (eventName) =>
      document.addEventListener eventName, @_handler

  _deinit: ->
    _.each @options.events, (eventName) =>
      document.removeEventListener eventName, @_handler

  _start: ->
    @timer = window.setTimeout =>
      @_idleAction()
    , @options.timeout

  _stop: ->
    window.clearTimeout(@timer)
    @timer = null

  _reset: ->
    @_stop()
    @_start()

  _idleAction: ->
    @_stop()
    @trigger 'idle'

# Extend class for Backbone events use
_.extend TimeIdler::, Backbone.Events

module.exports = TimeIdler
