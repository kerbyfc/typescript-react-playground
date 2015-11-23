###*
 * Sidebar region. Sidebar often contents lists, trees and other
 * navigation and workflow controls.
###
class SidebarRegion extends Marionette.Region

  el: "#layout__sidebar"

  sides: [
    "_left", "_right"
  ]

  modifiers:
    collapsed : "sidebar_collapsed"
    hidden    : "sidebar_hidden"

  toggler: ".sidebar__toggle"

  ###*
   * Subscribe to events
  ###
  initialize: ->
    @listenTo App.vent, "main:layout:hide:sidebar", @hide
    @listenTo App.vent, "main:layout:show:in:sidebar", @show
    @listenTo App.vent, "main:layout:sidebar:position", @realign

  ################################################################################
  # PRIVATE

  ###*
   * Toggle sidebar visibility
   * @param  {Event}
   * @return {Void}
  ###
  _toggle: (e) =>
    @toggle()
    @_trigger 'sidebar:start_transition'

  ###*
   * Get css class name that represents
   * sidebar position (aligment)
   * @param  {String} side
   * @return {String} class name
  ###
  _alignClass: (align) ->
    "#{ align }"

  ###*
   * Trigger event with instance and through App event bus
   * @param  {String} event
   * @param  {Array} args...
  ###
  _trigger: (event, args...) ->
    @trigger event, args...
    App.vent.trigger "sidebar:#{event}", args...

  ################################################################################
  # PUBLIC

  ###*
   * Realign sidebar to the left or right
   * @param  {Object} side
  ###
  realign: (side) ->
    @$wrapper
      .removeClass @sides.map(@_alignClass).join(" ")
      .addClass  @_alignClass "_#{side}"

  ###*
   * Make sidebar visible
  ###
  expand: ->
    App.Helpers.onTransition @$wrapper, =>
      @_trigger 'sidebar:show'
      App.trigger "resize", "sidebar", @
    @$wrapper.removeClass @modifiers.collapsed

  ###*
   * Make sidebar invisible
  ###
  collapse: ->
    App.Helpers.onTransition @$wrapper, =>
      @_trigger 'sidebar:hide'
      App.trigger "resize", "sidebar", @
    @$wrapper.addClass @modifiers.collapsed

  ###*
   * Toggle sidebar visibility
  ###
  toggle: =>
    if @$wrapper.hasClass @modifiers.collapsed
      @expand()
    else
      @collapse()

  ###*
   * Hide sidebar with toggler
  ###
  hide: ->
    @$wrapper?.hide() or if 1
      @show new Backbone.View
      @hide()

  ###*
   * Show sidebar (or only toggler) and
   * embed view inside
   * @param  {Marrionette.View} view
   * @param  {Object} options
  ###
  show: (view, options) =>
    super
    @$wrapper = @$el.closest "aside"

    $ @toggler, @$wrapper
      .off "click"
      .on  "click", @_toggle

    @$wrapper.show()
    @$wrapper.removeClass("#{@modifiers.hidden}")
    @$el.show()

module.exports = SidebarRegion
