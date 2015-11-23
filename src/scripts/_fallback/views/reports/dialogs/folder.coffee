"use strict"

module.exports = class FolderView extends Marionette.ItemView

  template: "reports/dialogs/folder"

  ui:
    inputs : "input, textarea, select"
    save   : "[data-action='save']"
    cancel : "[data-action='cancel'], .popup__close"
    name   : "[name='DISPLAY_NAME']"

  events:
    "click @ui.save"    : "_save"
    "click @ui.cancel"  : "_cancel"
    "change @ui.inputs" : "_change"
    "keyup @ui.inputs"  : "_change"

  disableModalClose: true

  behaviors: ->

    Form:
      listen: @options.model
      syphon: true
      preventSubmitDisabling: true

    Guardian:
      initial: true

      key: ->
        "reports:folder:#{@model.id}"

      title: ->
        action = @model.isNew() and "add" or "edit"
        App.t "reports.folder.#{action}_title"

      urlMatcher: ->
        "reports/folders/#{@model.id}/edit"

      content: ->
        App.t "reports.cancel_confirm"

      accept: ->
        @_back rollback: true

      omit: ->
        @_back()

  onDestroy: ->
    if @model.isNew()
      _.defer =>
        @model.destroy()

    App.vent.trigger "reports:forgot:folder"

  serializeData: ->
    _.extend super,
      isNew: @model.isNew()
      canBePrivatized: @model.can "privatize"

  onShow: ->
    @ui.name.focus().select()
    @on "form:submit", @_save

  ###########################################################################
  # PRIVATE

  ###*
   * Save report
   * @param  {Event} e
  ###
  _save: (e) =>
    e.preventDefault()
    @save()

  ###*
   * Handle form inputs change
   * @param  {Event} e
  ###
  _change: (e) =>
    @model.set Backbone.Syphon.serialize @

  ###*
   * Navigate back, rollback model if need, destroy view
   * unless destroy: false was passed
   * @param  {Object} options = {}
  ###
  _back: (options = {}) ->
    if options.rollback
      @model.rollback()

    unless options.destroy is false
      @destroy()

    App.vent.trigger "nav:back", "reports"

  ###*
   * Navigate back
   * @param  {jQuery.Event} e
  ###
  _cancel: (e) =>
    unless App.Config.reports.confirmCancel
      # dont ask for confirmation
      @model.rollback()
      @trigger "guardian:cleanup"

    e.preventDefault()
    @_back destroy: not @model.guardian

  ###########################################################################
  # PUBLIC

  save: ->
    unless @model.validate()

      data = @getData()
      data.IS_PERSONAL = +data.IS_PERSONAL

      @model.save data,
        wait: true
        success: (model) =>
          @trigger "guardian:cleanup"

          App.vent.trigger "reports:folder:save", @model
          App.vent.trigger "nav", "reports/folders/#{model.id}"
          @destroy()
