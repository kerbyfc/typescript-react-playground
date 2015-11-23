"use strict"

require "bootstrap"
require "jquery-ui"

class App.Layouts.ConfirmDialog extends Marionette.LayoutView

  template: "dialogs/confirm"

  regions:
    content: "#popup__content"

  ui:
    close  : ".popup__close"
    accept : "[data-action='accept']"

  events:
    "click @ui.accept" : "_accept"
    "keypress"       : "_maybeenter"
    "keyup"        : "_maybeesc"

  initialize: (options) ->
    @options  = _.defaults {}, options,
      confirm : App.t 'confirm.confirm'
      cancel  : App.t 'confirm.cancel'

    @accepted = false

  ###*
   * Should be invoked on canceling / clicking on overlay, etc.
  ###
  onDestroy: ->
    unless @accepted
      @options.reject? @options
    @options.always? @options
    true

  ###*
   * Mixin options to template locals
   * @return {Object} template locals
  ###
  serializeData: ->
    data = _.extend {}, super, @options

    _.extend data, @options

    ###*
     * for backward capability
     * @deprecated
    ###
    data.content ?= @options.data
    data

  ################################################################################
  # PRIVATE

  ###*
   * Determine if enter button was pressed
   * @param  {Event} e
  ###
  _maybeEnter: (e) =>
    code = e.keyCode or e.which
    if code is 13 and e.target.tagName isnt "TEXTAREA"
      e.preventDefault()
      @accept e, "ok"

  ###*
   * Determine if esc button was pressed
   * @param  {Event} e
  ###
  _maybeEsc: (e) =>
    code = e.keyCode or e.which
    if code is 27
      e.preventDefault()
      @destroy()

  ###*
   * Handle success button click
   * @param  {Event} e
  ###
  _accept: (e) =>
    e?.preventDefault()
    @accept e, $(e.target).data "index"

  ################################################################################
  # PUBLIC

  ###*
   * Accept with code, which may be a button index formed by
   * confirm option, or enter
   * @param  {Event} e
   * @param  {String} code
  ###
  accept: (e, code) ->
    @options.accept? code, e, @options
    @accepted = true
    @destroy()

  reject: ->
    @destroy()
