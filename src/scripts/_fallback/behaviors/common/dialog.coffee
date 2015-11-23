"use strict"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Dialog extends Marionette.Behavior

  defaults: ->
    close  : ".popup__close,.popup__wrap"
    ok     : ":submit"
    cancel : ":reset"
    title  : =>
      options = @view.options
      selected = options.selected

      if not selected or selected.length < 2
        item = App.t "select_dialog.#{options.type}", context: "title"
      else
        item = App.t "select_dialog.#{options.type}_plural_5"

      App.t "global.#{options.action}",
        context : "title"
        item    : item.toLowerCase()

  disableButton: (state) ->
    @$el.find(@defaults.ok).prop 'disabled', state

  onRender: ->
    title = @view.options.title

    title = _.result @options, "title" unless title
    @options.title = title

    wrapper = Marionette.Renderer.render "controls/dialog/wrapper", @options
    wrapper = $ wrapper
    wrapper
    .find '.popup__title'
    .after @$el.children()
    @$el.append wrapper

  events:
    "click :submit"       : "save"

    # "click .popup__wrap"  : "onCancel"
    "click :reset"        : "onCancel"
    "click .popup__close" : "onCancel"

    "keypress"            : "onKeyPress"
    "keyup"               : "onKeyPress"

  save: (e) ->
    e?.preventDefault()
    type = $ e.currentTarget
    .data "type"

    data = @view.get? arguments...

    @view.options.callback.apply @, [data, type]

  onCancel: (e) ->
    return unless e

    e.preventDefault() if e.currentTarget.type is "reset"

    if "popup__wrap" in e.currentTarget.classList and
    e.currentTarget isnt e.target
      return

    if @view.model and not @view.model.isNew() and
    @view.prev and not _.isEqual(@view.prev, @view.model.toJSON())
      @view.model?.fetch()

    @view.options.onCancel?()

    App.modal.empty() if App.modal.currentView is @view
    App.modal2.empty() if App.modal2.currentView is @view

  onKeyPress: (e) ->
    code = e.keyCode or e.which

    if code is 27
      e.preventDefault()
      @onCancel()
