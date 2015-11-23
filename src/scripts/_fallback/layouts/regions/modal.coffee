###*
 * Region for any modal dialog with busyness logic
###
class ModalRegion extends Marionette.Region

  el: "#modal"

  ###*
   * Ui elements selectors (aka view)
   * @type {Object}
  ###
  ui:
    popup      :  ".popup"
    indent     :  ".popup__indent"
    firstInput :  "input:text:visible:first"
    toggler    :  ".popup__toggle"

    # close triggers
    close  : ".popup__close"
    wrap   : ".popup"
    cancel : "[data-action='cancel']"

  ###*
   * List of elements, thats will
   * trigger modal dialog closing
   * @see #ui
   * @type {Array}
  ###
  closeTriggers: ["close", "cancel", "wrap"]

  ###*
   * Bind events, show dialog
  ###
  onShow: (view) =>
    @_ui("toggler").attr "checked", "checked"
    @_ui("firstInput").focus()
    @_ui("indent").draggable handle: ".popup__title"

    for el in @_getCloseTriggers()
      el.on "click", @_close

  ###*
   * Empty region only if current view approves it's closing and
   * after transition ends
   * @override
  ###
  empty: ->
    args = arguments

    if view = @currentView
      view.triggerMethod "modal:close"

      el.off "click", @_close for el in @_getCloseTriggers()

      App.Helpers.onTransition @_ui("popup"), =>
        super args...

      # start hide transiontion (or just hide)
      @_ui("toggler").removeAttr "checked"

  ################################################################################
  # PRIVATE

  ###*
   * Get ui elements, that initiate modal view closing
  ###
  _getCloseTriggers: ->
    _.map @closeTriggers, (el) => @_ui el

  ###*
   * Handle clicks to some els to close region & view
   * @param  {Event} e
  ###
  _close: (e) =>
    for el in @_getCloseTriggers()
      e?.preventDefault() if el.is e.target

    if view = @currentView
      return if view.disableModalClose?

      target = $ e.target
      for el in @_getCloseTriggers() when el.is target
        return @empty view.region_options

  ###*
   * Get ui el by key
   * @param  {String} key
   * @return {jQuery} jQuery element
  ###
  _ui: (key) ->
    @$el.find @ui[key]

###*
 * For modal views on top of modal views (confirmations, etc)
###
class OverModalRegion extends ModalRegion
  el: "#modal2"

module.exports =
  ModalRegion   : ModalRegion
  OverModalRegion : OverModalRegion
