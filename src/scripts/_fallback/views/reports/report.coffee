"use strict"

require "behaviors/common/guardian.coffee"

Widget    = require "models/reports/widget.coffee"
Selection = require "models/events/selections.coffee"

WidgetGridView  = require "views/reports/grid.coffee"
ConditionsQuery = require "views/events/query_builder/conditions_query.coffee"

# TODO use Composite view right after widgets views should be merged to devel
module.exports = class ReportView extends Marionette.LayoutView

  template: "reports/report"

  className: "content"

  ui:
    save          : "[data-action='save']"
    execute       : "[data-action='save_execute']"
    add           : "[data-action='add_widget']"
    cancel        : "[data-action='cancel']"
    name          : "[name='DISPLAY_NAME']"
    personal      : "[name='IS_PERSONAL']"
    period        : "[name='OPTIONS[useCommonPeriod]']"
    widgets       : "[data-widget-id]"
    editModeMsg   : "[data-edit-mode-msg]"
    scrollable    : "[data-content]"
    affix         : "[data-affix]"

  regions:
    commonPeriod      : "[data-region='commonPeriod']"
    widgetGridRegion  : "[data-region='widgetGrid']"

  events:
    "click @ui.save"    : "_save"
    "click @ui.execute" : "_saveAndExecute"
    "click @ui.cancel"  : "_cancel"
    "click @ui.widgets" : "_edit"
    "click @ui.add"     : "_addWidget"
    "change @ui.period" : "_setPeriod"

  getData: ->
    @model.toJSON()

  behaviors: ->

    Guardian:
      key: ->
        "reports:report:#{@model.id}"

      title: ->
        action = @model.isNew() and 'add' or 'edit'
        App.t "reports.report.#{action}_title"

      urlMatcher: (fragment) ->
        ///reports/#{@model.id}\////.test fragment

      attendNavigation: (fragment, match) ->
        if not match
          @model.navOnDestroy = fragment
          @_markAsActive()

      content: ->
        App.t "reports.cancel_confirm"

      restore: (model, data) ->
        model.set model.parse data

      accept: ->
        @model.rollback()

        # state was changed by activation another node in tree
        if @model.navOnDestroy
          App.vent.trigger "nav", @model.navOnDestroy

    Form:
      listen         : @options.model
      syphon         : true
      isAutoValidate : true

      # TODO: now can't correctly disable/enable buttons
      preventSubmitDisabling: true

  constructor: (options) ->
    @model = options.model

    @listenTo @model.widgets, "change reset add remove", =>
      @trigger "guardian:guard"

    super

  onShow: ->
    @ui.name.focus().select()

    # Prepare models
    @commonPeriodQueryMixin = periodModel = new Selection.model
      QUERY:
        mode: 'advanced'
        data:
          children      : @model.getQueryReplacements()
          link_operator : "and"

    # Prepare views
    gridView = new WidgetGridView
      report: @model
      collection: @model.widgets
      mode: "edit"

    # Fill regions
    @widgetGridRegion.show gridView
    @commonPeriod.show new ConditionsQuery
      conditions:
        general: ['capture_date']

      model : periodModel
      mode  : "advanced"

      # exclude titles/conditions
      exclude : [
        'general'
      ]

    # Add listeners
    gridView.on "add", @_scrollToWidget

    @listenTo @model.widgets, "change reset add remove", @_updateControls
    @listenTo @commonPeriod.currentView.condition_model,
      "rebuild invalid", @_updateButtons

    @ui.scrollable.on "scroll", @_observeAffix
    @on "form:submit", @_save
    @on "form:change", @_updateButtons

    # Do initial form update
    @_updateControls()
    @_updateEditModeMsg()
    @_updateButtons()

  onDestroy: ->
    @ui.scrollable.off "scroll"
    if @model.isNew()
      _.defer =>
        @model.destroy()

    App.vent.trigger "forgot:folder"

  templateHelpers: ->
    _.extend @model.toJSON(),
      isNew : @model.isNew()
      runs  : @model.runs
      canBePrivatized: @model.can "privatize"

  ###########################################################################
  # PRIVATE

  ###*
   * Check if with current page scroll
   * @ui.affix will be fixed/released
   * @param {jQuery.Event} e - scroll event
  ###
  _observeAffix: (e) =>
    isFixed     = @ui.affix.hasClass "_fixed"
    parent      = @ui.affix.parent()
    willBeFixed = parent.position().top - 5 <= 0

    if isFixed isnt willBeFixed

      if willBeFixed
        @ui.affix.addClass "_fixed"
        parent.css height: @ui.affix.height()

      else
        @ui.affix.removeClass "_fixed"
        parent.css height: "auto"

    true

  ###*
   * Handle cancel button click
   * @param {jQuery.Event} e
  ###
  _cancel: (e) ->
    e.preventDefault()

    unless App.Config.reports.confirmCancel
      # dont ask for confirmation
      @model.rollback()
      @trigger "guardian:cleanup"

    unless @model.isNew()
      App.vent.trigger "nav", "reports/#{@model.id}"
    else
      App.vent.trigger "nav", "reports"

  ###*
   * Navigate to report edit form
   * @param  {jQuery.Event} e
  ###
  _edit: (e) ->
    e.preventDefault()
    if id = $(e.currentTarget).data "widget-id"
      App.vent.trigger "nav", "reports/#{@model.id}/widgets/#{id}"

  ###*
   * Save report
   * @param  {Event} e
  ###
  _save: (e) =>
    e.preventDefault()
    @save @_saveOptions()

  _saveOptions: ->
    success: =>
      @destroy()
      @trigger "guardian:cleanup"

      # tell controller to add report to proper folder and navigate
      App.vent.trigger "reports:report:save", @model
      App.vent.trigger "nav", "reports/#{@model.id}"

  ###*
    and then execute report
   * @param  {jQuery.Event} e
  ###
  _saveAndExecute: (e) =>
    e.preventDefault()
    @save().done =>
      @model.execute @_saveOptions()

  ###*
   * Navigate to widget create form, cleanup widget and query caches
   * @param {[type]} e [description]
  ###
  _addWidget: (e) ->
    e.preventDefault()
    localStorage.removeItem "reports:widget:new"
    localStorage.removeItem "reports:widget:new:query"
    App.vent.trigger "nav", "reports/#{@model.id}/widgets/new"

  ###*
   * Update controls accessability
  ###
  _updateControls: ->
    @ui.execute.attr "disabled", =>
      unless @model.can "execute"
        return "disabled"
      null

    @ui.personal.attr "disabled", =>
      if userId = @model.get "USER_ID"
        if userId isnt App.Session.currentUser().id
          return "disabled"
      null

    @commonPeriod.currentView.$el.toggle @ui.period.is ":checked"
    @_updateEditModeMsg()

  ###*
   * Make active proper tree node
  ###
  _markAsActive: =>
    App.request "reports:tree:set:active:node", "report:#{@model.id}", true,
      noEvents: true

  _setPeriod: ->
    @_updateControls()
    @_setCommonPeriod()

  _getCommonPeriodCondition: ->
    @commonPeriod.currentView.condition_model.children.findWhere
      category: "capture_date"

  ###*
   * Set model OPTIONS, toggle common period control availability
   * @return {[type]} [description]
  ###
  _setCommonPeriod: (data) ->
    data ?= @serialize()

    @model.set "OPTIONS", _.extend {}, @model.get("OPTIONS"),
      useCommonPeriod: data.OPTIONS.useCommonPeriod
      replace: [@_getCommonPeriodCondition()?.toJSON()]

    @_updateButtons()

  _updateEditModeMsg: ->
    if @model.widgets.size()
      @ui.editModeMsg.show()
    else
      @ui.editModeMsg.hide()

  _scrollToWidget: (widget) =>
    @ui.scrollable.scrollTo widget.$el, 100, easing: "easeOutQuart"

  _updateButtons: =>
    valid = not @model.validate @serialize()

    # validate common period
    if valid and @model.isCommonPeriodUsed()
      valid = valid and not @_getCommonPeriodCondition()?.validate()

    @_toggleButtons valid

  _toggleButtons: (enabled) ->
    @ui.save.attr 'disabled', not enabled
    @ui.execute.attr 'disabled', not(enabled and @model.can "execute")

  ###########################################################################
  # PUBLIC

  ###*
   * Save report
   * @return {jQuery.Deferred}
  ###
  save: (options = {}) =>
    unless @model.validate()
      data = @serialize()
      data.IS_PERSONAL = +data.IS_PERSONAL

      @_setCommonPeriod data
      delete data.OPTIONS

      @model.save data, _.extend wait: true, options

  ###*
   * Execute report, show success message
  ###
  execute: =>
    @model.execute()
