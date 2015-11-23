"use strict"

###*
 * @method #onDestroy
 * Element destructor.
 * TODO: Think about some default destructing
 *
 * @method #onShow
 * TODO: Think about some logic on showing element
###
module.exports = class InputFormComponent extends Marionette.Object

  constructor: (el, context) ->
    @$el = $ el
    @container = context.el

    @ui = _.result @, 'ui'

    method = if @jquery and not @preventSetJquery then 'setJquery' else 'setEvents'
    @listenToOnce context, 'show', @[method]

    @listenTo context, 'destroy', @destroy
    @listenTo context, 'show', @onShow

  setJquery: ->
    return unless @jquery
    defaults = _.result @, 'defaults'
    defaults = [defaults] unless _.isArray defaults
    @$el[@jquery].apply @$el, defaults

    @setEvents()

  setEvents: ->
    events = _.result @, 'events'

    for event of events
      @$el.on event, events[event]
