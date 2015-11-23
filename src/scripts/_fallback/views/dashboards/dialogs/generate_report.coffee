"use strict"

StatTypes = require "models/dashboards/stattype.coffee"

###*
 * The item of widget to set up in dashboard report
 *
###
class Widget extends Marionette.ItemView

  className: "form__block"

  tagName : "form"

  template: "dashboards/dialogs/generate_report_widget"

  behaviors: ->

    Form:
      listen: @options.model
      syphon: true
      isAutoValidate: true

  templateHelpers: ->
    displayname : @model.getName() or App.t('dashboards.widgets', { returnObjectTrees: true })["#{@stattype}_name"]
    stattype    : @stattype

  ui:
    details       : "[name='details']"
    details_count : "[name='details_count']"
    startPeriod   : "[data-period='start']"
    endPeriod     : "[data-period='end']"

  initialize: (options = {}) ->
    super
    { @report } = options

    stattypeId    = @model.get("STATTYPE_ID")
    stattypeModel = StatTypes.StatTypesInstance.get(stattypeId)
    @stattype     = stattypeModel.get("STAT")

    @listenTo @, "form:change", @_onFormChanged
    @listenTo @report, "change", @_updatePeriod

  # in case of user reopened window with previous model
  onShow: ->
    @model.validate()
    # Initiate form state
    @updateUI()

  # handle checkboxes and disabled elements
  _onFormChanged: (data) =>
    # Copy form data
    @model.set(data, {forceUpdate: true, validate:true})
    @updateUI()

  _updatePeriod: ->
    reportParams = @report.get("PARAMS")

    period = if reportParams?.main_period
      [moment(reportParams.start_period), moment(reportParams.end_period)]
    else
      @model.createWidgetInterval()

    @ui.startPeriod.html period[0].format("L")
    @ui.endPeriod.html period[1].format("L")

  # setup ui according to model's data
  updateUI: ->
    includeInReport = @model.get("includeInReport")
    useDetails      = @model.get("details")
    validate = false
    # set attribute to notify parent collection about changes

    if not includeInReport
      @ui.details.prop("disabled", true)
    else
      @ui.details.removeAttr("disabled")
      @ui.details_count.removeAttr("disabled")

    if includeInReport and useDetails
      if @ui.details_count.prop("disabled") or @ui.details.prop("disabled")
        @ui.details.removeAttr("disabled")
        @ui.details_count.removeAttr("disabled")
    else
      # HACK: to remove error popover
      @model.trigger "form:reset"
      @ui.details_count.prop("disabled", true)

    @_updatePeriod()

###*
 * List of Items (widgets) for the dashbaord report
###
class List extends Marionette.CollectionView

  childView : Widget

  filter: (model, index, collection) ->
    model.get("STATTYPE_ID") isnt 4

  childViewOptions: ->
    report: @options.report

###*
 * Renders settings of the dashboard report
###
class Header extends Marionette.ItemView

  template: "dashboards/dialogs/generate_report_head"

  behaviors: ->
    Form:
      listen : @options.model
      syphon : true
      isAutoValidate : true

  ui:
    name    : "[name='DISPLAY_NAME']"
    pickers : "[data-form-component='date-range-picker']"

  onShow: =>
    @model.validate()
    @listenTo @, "form:change", @_onFormChanged
    @_onFormChanged()

  _onFormChanged: (data) ->
    if data?.PARAMS
      modelPARAMS = @model.get "PARAMS"
      @model.set "PARAMS", _.assign {}, modelPARAMS, data.PARAMS
      delete data.PARAMS

    @model.set(data, {forceUpdate: true, validate:true})

    if @model.get("PARAMS").main_period is 1
      @ui.pickers.removeAttr("disabled")
    else
      @ui.pickers.prop("disabled", true)


###*
 * Dialog Layout combines Head nad List.
 * This dialog has own submit action to save model.
 * Each time dialog view checks for
 * valid DashboardReport model and Widgets collection
###
module.exports = class WidgetsReportDialog extends Marionette.LayoutView

  template: "dashboards/dialogs/generate_report"

  regions:
    headRegion : "[data-region='header']"
    listRegion : "[data-region='list']"

  headerView : null
  listView   : null

  ui:
    submit : "[data-action='save']"
    cancel : "[data-action='cancel']"

  events:
    "click [data-action='save']" : "onSave"

  onSave: =>
    @destroy()
    @callback?(@model)

  initialize: (options) ->
    super
    @callback = options.callback
    @listenTo options.model, "change change:widgets", @_onModelChange

  _onModelChange: (e) =>
    @ui.submit.prop "disabled", not @model.isValid()

  onShow: ->

    @headerView = new Header
      model : @model

    @listView = new List
      collection : @model.widgets
      report     : @model

    @showChildView("headRegion", @headerView)
    @showChildView("listRegion", @listView)
