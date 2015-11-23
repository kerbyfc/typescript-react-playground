"use strict"
require "behaviors/common/guardian.coffee"

Selection             = require "models/events/selections.coffee"
ConditionsQuery       = require "views/events/query_builder/conditions_query.coffee"
AdvancedQuery         = require "views/events/query_builder/advanced_conditions_query.coffee"

helpers    = require "common/helpers.coffee"
conditions = require "settings/conditions"
storage    = require "local-storage"
flat       = require "flat"

# object_id should not be used in widgets
if general = conditions.general
  conditions = _.cloneDeep conditions
  conditions.general = _.without general, "object_id"

module.exports = class ReportWidgetView extends Marionette.LayoutView

  template: "reports/dialogs/widget"

  regions:
    queryBuilder: "[data-region='query-builder']"

  disableModalClose: true

  behaviors: ->
    Guardian:

      key: ->
        "reports:report:widget"

      title: ->
        action = @model.isNew() and 'add' or 'edit'
        App.t "reports.widget.#{action}_title"

      content: ->
        App.t "reports.cancel_confirm"

      needConfirmation: ->
        @model.isDirty()

      urlMatcher: ->
        "reports/#{@report.id}/widgets/#{@model.id}"

      backup: (model) ->
        data = model.toJSON()
        data

      restore: (model, data) ->
        model.set model.parse data

      accept: ->
        @_back()

    Form:
      listen: @options.model
      syphon: true
      select: "select:not([data-action='copy'])"

      isAutoValidate         : true
      preventSubmitDisabling : true


  ui:
    save        :  "[data-action='save']"
    chartTypes  :  "[data-view]"
    tabs        :  "[data-tab]"
    widgetTypes :  "[name='WIDGET_TYPE']"
    name        :  "[name='DISPLAY_NAME']"
    cancel      :  "[data-action='cancel'], .popup__close"
    options     :  "[data-option]"
    copy        :  "[data-action='copy']"
    mode        :  "[data-mode-toggler]"
    period      :  "[name='OPTIONS.groupingByPeriod']"
    limit       :  "[name='OPTIONS.limit']"
    levels      :  "[name^='OPTIONS.violationLevels.']"

  events:
    "click @ui.save"         : "_save"
    "click @ui.cancel"       : "_cancel"
    "click @ui.chartTypes"   : "_setChartType"
    "change @ui.widgetTypes" : "_setWidgetType"
    "change @ui.mode"        : "_toggleQueryMode"
    "change @ui.levels"      : "_lockLastSelectedViolationLevel"
    "click @ui.tabs"         : "_changeTab"
    "change @ui.copy"        : "_copyQuery"

  ###*
   * Available query builer modes
   * @type {Array}
  ###
  modes: [
    "lite"
    "advanced"
  ]

  ###*
   * Create models, collections, add listeners
   * @param  {Object} options
  ###
  initialize: (options) ->
    {@report, @queries, @tab} = options

    # Setup query model and fetch it
    if @model.query.isNew()

      # if nested model is new, but there are query id in widget model ...
      if queryId = @model.get "QUERY_ID"
        @model.query
          .set QUERY_ID: queryId
          # TODO: report queries must not fetched by @queries
          # (lazy load one by one)
          .fetch()

    @listenTo @model, "change" , @update
    @listenTo @queries, "reset update", @_updateQueriesList

    # selection query doesn't trigger change, so
    # it can only affect on query builder mode
    @listenTo @model.query, "change:query:mode", (mode) =>
      @trigger "guardian:guard"
      @_renderQueryBuilder()

  templateHelpers: ->
    isNew   : @model.isNew()
    views   : @model.views
    periods : @model.periods
    types   : @model.types
    mode    : @model.query.getMode() or "lite"
    modes   : @modes
    tab     : @tab in ["view", "query"] and @tab or "view"
    levels  : _.keys @model.violationLevels

  ###*
   * Fill form, bind validation, update controls
  ###
  onShow: ->
    Backbone.Syphon.deserialize @, @model.toJSON()
    Backbone.Validation.bind @

    @listenTo @, "form:change", =>
      @model.set @serialize()

    @_updateQueriesList()
    @_renderQueryBuilder()
    @update()

  ###########################################################################
  # PRIVATE

  ###*
   * Update model data with Syphon
   * @param  {Event} e
  ###
  _update: (e) ->
    e.preventDefault()
    @update()

  ###*
   * Change current url to proper tab
   * @param {jQuery.Event} e
  ###
  _changeTab: (e) ->
    url = "/reports/#{@report.id}/widgets/#{@model.id}/#{e.target.dataset.tab}"
    App.vent.trigger "nav", url, trigger: false

  ###*
   * Handle close buttons or overlay click
   * @param  {Event} e
  ###
  _cancel: (e) =>
    e.preventDefault()
    @cancel()

  ###*
   * Copy query attributes to widget query
   * @param  {jQuery.Event} e
  ###
  _copyQuery: (e) ->
    query = @model.query

    # it doesn't matter what name should have query
    # report will set in on save
    name = new Date().toString()

    queryId = e.target.value

    # copy query
    @queries.get(queryId).copy name, query

    query.rejectConditions ["object_id"]
    query.set copy: true

    query.once "change", =>
      @model.query.unset "copy", silent: true
      @ui.copy.select2("val", null)

    # if select copy from select and then repeat this
    # action one more time, then select should be empty
    @ui.copy.select2("val", queryId)

    @_renderQueryBuilder()

  ###*
   * Handle save button click
   * @param  {Event} e
  ###
  _save: (e) ->
    Backbone.Syphon.serialize @
    e.preventDefault()
    @save()

  ###*
   * Setup and fill with data query selector, that can
   * be used to copy they configuration
  ###
  _updateQueriesList: _.throttle [ leading: false, 50, ->

    queries = @queries
      .filter (model) ->
        model.get("QUERY_TYPE") is "query"
      .map (model) ->
        id   : model.id
        text : model.getName().toLowerCase()

    @ui.copy.select2
      data        : queries
      width       : 400
      placeholder : "
        #{_.capitalize App.t("global.copy")}
        #{App.t("reports.query").toLowerCase()}
      "

  ].reverse()...

  ###*
   * Update view type buttons availability, mark current as active
  ###
  _updateViewToggler: ->
    type = @model.get "WIDGET_TYPE"
    view = @model.get "WIDGET_VIEW"

    for _view in @model.views
      $ "[data-view='#{_view}']"
        .prop "disabled", =>
          unless type and @model.isConsistent(type: type, view: _view)
            return true
          false
        .toggleClass "active", (view is _view)

  ###*
   * Update list of statistic types
  ###
  _updateStatTypes: ->
    view = @model.get("WIDGET_VIEW")

    # render options
    @ui.widgetTypes.select2
      minimumResultsForSearch: Infinity
      placeholder: App.t "reports.widget.type_hint"

      # fill
      data: _.sortBy(@model.types
        .map((option) ->
          id   : option
          text : App.t "reports.widget.types.#{option}"
        ), 'text')

    if type = @model.get "WIDGET_TYPE"
      @ui.widgetTypes.select2('val', type)

  ###*
   * Reset options visibility for proper chart type
  ###
  _updateOptionsVisibility: (e) ->
    view = @model.get "WIDGET_VIEW"
    type = @model.get "WIDGET_TYPE"

    # hide or show options
    for option in _.keys @model.getOptions()
      el = @$ "[name='#{option}']"
      el.closest "[data-option]"
        .attr "data-hidden", =>
          unless @model.isConsistent(view: view, option: option) or @model.isConsistent(type: type, option: option)
            return "yes"
          null

  _toggleQueryMode: (e) ->
    e.preventDefault()
    @model.query.setMode(@ui.mode.val())

  ###*
   * Render advanced or lite query builder view
   * in depend of current mode
   * Also ensure current mode is actual
  ###
  _renderQueryBuilder: =>
    query = @model.query
    mode = query.getMode()
    isCommonPeriodUsed = @report.isCommonPeriodUsed()
    viewClass = if mode is "lite" then ConditionsQuery else AdvancedQuery

    view = new viewClass
      # TODO: remove mode option
      mode: mode

      model   : query
      exclude : ['object_id', 'general']

      afterRender: (view) ->
        return if not isCommonPeriodUsed

        if mode is "lite" or view.model.get('category') is 'capture_date'
          # TODO: #onDomRefresh should be called before component`s #onShow
          _.defer ->
            view.$("[name*='capture_date']").hide()
            interval = view.$("[name='capture_date[interval]']").parent()
            interval.hide()
            interval.next().hide()
              .after Marionette.Renderer.render "reports/misc/common_period_hint"

    @ui.mode.select2("val", mode)
    @queryBuilder.show view

  ###*
   * Navigate back, rollback model if need, destroy view
   * unless destroy: false was passed
   * @param  {Object} options = {}
  ###
  _back: (options = {}) ->
    unless options.afterSave
      # if widget was added to report, then don't destroy it
      if @report.widgets.get @model
        @model.rollback()
      else
        @model.destroy()

      # ensure view should be destroyed
      options.destroy = true

    unless options.destroy is false
      # dont ask for confirmation
      @trigger "guardian:cleanup"

      @destroy()

    _.defer =>
      App.vent.trigger "nav", "reports/#{@report.id}/edit"

  _setChartType: (e) ->
    e.preventDefault()

    el = $(e.currentTarget)
    if not el.is(":disabled")
      chartType = el.data("view")
      @model.setChartType(chartType)

  _setWidgetType: (e) ->
    e.preventDefault()

    widgetType = @ui.widgetTypes.val()
    @model.setWidgetType(widgetType)

  _lockLastSelectedViolationLevel: ->
    selectedViolationLevels = @model.getSelectedViolationLevels()
    if selectedViolationLevels.length is 1
      lastSelectedLevel = selectedViolationLevels[0].toLowerCase()
      @ui.levels.filter("[name$='#{lastSelectedLevel}']").prop('disabled', true)
    else
      @ui.levels.filter(':disabled').prop('disabled', false)

  ###########################################################################
  # PUBLIC

  update: ->
    Backbone.Syphon.deserialize @, @model.toJSON()

    @trigger "guardian:guard"
    # to cache report widgets
    # in Local Storage by Guardian
    @report.trigger "guardian:guard"

    @_updateViewToggler()
    @_updateStatTypes()
    @_updateOptionsVisibility()
    @_lockLastSelectedViolationLevel()

  ###*
   * Save widget model by report model saving
   * Save query first
   * # TODO refactoring
   * @return {jQuery.Deferred}
  ###
  save: ->
    unless @model.validate()
      # save query first
      # @_mergeQueryBuilderForm()
      @stopListening @model

      @model.backup()
      @report.backup()
      @report.widgets.resolveUniqueWidgetName @model
      @report.widgets.add @model

      @trigger "guardian:cleanup"

      @_back afterSave: true

  ###*
   * Navigate back on close
  ###
  cancel: ->
    @stopListening @model
    @_back destroy: not(App.Config.reports.confirmCancel and @model.guardian)
