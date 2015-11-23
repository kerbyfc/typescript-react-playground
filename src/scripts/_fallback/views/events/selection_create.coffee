"use strict"

AdvancedQueryParams       = require "views/events/query_builder/advanced_query_prop.coffee"
ConditionDialog           = require "views/events/query_builder/conditions_query.coffee"
AdvancedConditionsDialog  = require "views/events/query_builder/advanced_conditions_query.coffee"
AccessView                = require "views/events/query_builder/access_query_prop.coffee"

module.exports = class QueryCondition extends Marionette.LayoutView

  getTemplate: ->
    if @options.mode is 'lite'
      "events/query_builder/lite_selection"
    else
      "events/query_builder/advanced_selection"

  ui:
    display_name  : '[name="DISPLAY_NAME"]'

  events:
    'click [data-action="save"]'                : 'saveCondition'
    'click [data-action="save_and_execute"]'    : 'saveCondition'
    'click [data-action="cancel"]'              : 'cancelCreateEdit'
    'click [data-action="switch_to_advanced"]'  : 'switchToAdvanced'

  _checkUserId: (model) ->
    return not model.has('USER_ID') or model.get('USER_ID') is App.Session.currentUser().get('USER_ID')

  regions: (options) ->
    regions =
      condition_params  : '[data-region="condition_params"]'
      advanced_params   : '[data-region="advanced_params"]'

    if @_checkUserId(options.model)
      regions['access'] = '[data-region="access"]'

    regions

  templateHelpers: ->
    title: @options.title

  cancelCreateEdit: (e) ->
    e?.preventDefault()

    @options.callback(true)

    @destroy()

  switchToAdvanced: (e) ->
    e.preventDefault()

    @model.set 'DISPLAY_NAME', @ui.display_name.val()

    @trigger 'switchToAdvanced'

  showErrorHint: (attr, error) ->
    if @ui[attr].data("bs.popover")
      @ui[attr].popover("destroy")

    position = @ui[attr].data("tooltip-position") or "right"

    @ui[attr].popover(
      placement: position
      trigger: "manual"
      content: error
      container: @ui[attr].closest("[data-error-container]")
    )
    @ui[attr].popover('show')

  saveCondition: (e) ->
    e?.preventDefault()

    data = {}
    data['DISPLAY_NAME'] = @ui.display_name.val()

    if @options.mode is 'lite'
      if not @condition_params.currentView.condition_model.isValid()
        return
    else
      if not @condition_params.currentView.conditions.currentView.model.isValid()
        return

    if $(e.target).data('action') is 'save_and_execute'
      @options.callback(false, data, true)
    else
      @options.callback(false, data)

  onShow: ->
    if @options.extendedClasses
      @$el.addClass @options.extendedClasses

    Backbone.Validation.bind(@)

    @ui.display_name.val(@model.get 'DISPLAY_NAME')

    @advanced_params.show new AdvancedQueryParams
      model: @model

    if @_checkUserId(@model)
      @access.show new AccessView
        model: @model

    if @options.mode is 'lite'

      @condition_params.show new ConditionDialog
        model : @model

    else
      @condition_params.show new AdvancedConditionsDialog
        model : @model

  onDestroy: ->
    Backbone.Validation.unbind(@)
