"use strict"

module.exports = class TaskEditForm extends Marionette.ItemView

  template: "crawler/tasks/task"

  className: "content"

  templateHelpers: ->
    title                 : @options.title
    SCAN_POLICIES         : @options.model.SCAN_POLICIES
    SHAREPOINT_VERSIONS   : @options.model.SHAREPOINT_VERSIONS
    SCAN_MODES            : @options.model.SCAN_MODES
    SCHEDULE_TYPES        : @options.model.SCHEDULE_TYPES
    SCHEDULE_DAYS         : @options.model.SCHEDULE_DAYS
    MOUNTH_DAYS           : @options.model.MOUNTH_DAYS

  ui:
    scanPolicySharepoint    : ".scan_policy_sharepoint"
    scanSharepoint2013      : ".sharepoint_2013"
    scanSharepointAbove2013 : ".sharepoint_above_2013"
    scanPolicyShares        : ".scan_policy_shares"
    scanFilterPaths         : ".filter_paths"
    credentials             : ".credentials"
    scheduleWeekly          : ".schedule_weekly"
    scheduleDaily           : ".schedule_daily"
    scheduleMonthly         : ".schedule_monthly"
    cancelButton            : "button.cancel_button"
    submitButton            : "[data-action='save']"
    scheduleType            : "select[name='Schedule[type]']"
    useScanCredentials      : "input[name='FileSystem[Credentials][useLocal]']"
    scanMode                : "select[name='scanMode']"
    scanPolicy              : "select[name='scanPolicy']"
    filters                 : "input[name='Filters[MaskFilter]']"
    sharepointVersion       : '[name="sharepointVersion"]'


  events:
    "click @ui.submitButton": "save"
    "click @ui.cancelButton": "cancel"

  behaviors: ->
    data = @options.model.toJSON()

    Form:
      listen: @options.model
      syphon: data

  onShow: ->
    @ui.filters.select2
      tags: @model.FILE_FILTERS
      formatSelection: (selection) -> "*.#{selection.text}"
      formatResult: (selection) -> "*.#{selection.text}"

    if @model.get("scanPolicy") is "sharepoint"
      @ui.scanPolicyShares.hide()

      if @model.get("sharepointVersion") is "2013"
        @ui.scanSharepointAbove2013.hide()
      else
        @ui.scanSharepoint2013.hide()
    else
      @ui.scanPolicySharepoint.hide()

    # TODO: move to events
    @ui.sharepointVersion.on "change", (event) =>
      if $(event.currentTarget).val() is "2013"
        @ui.scanSharepointAbove2013.slideUp()
        @ui.scanSharepoint2013.slideDown()
      else
        @ui.scanSharepointAbove2013.slideDown()
        @ui.scanSharepoint2013.slideUp()

    @ui.scanPolicy.on "change", (event) =>
      if $(event.currentTarget).val() is "sharepoint"
        if @ui.scanPolicySharepoint.is(":hidden")
          @ui.scanPolicyShares.slideUp().promise()
          .then =>
            @ui.scanPolicySharepoint.slideDown()

            sharepointVersion = @ui.sharepointVersion.select2('val')
            if sharepointVersion is "2013"
              @ui.scanSharepointAbove2013.slideUp()
              @ui.scanSharepoint2013.slideDown()
            else
              @ui.scanSharepointAbove2013.slideDown()
              @ui.scanSharepoint2013.slideUp()
      else
        if @ui.scanPolicyShares.is(":hidden")
          @ui.scanPolicySharepoint.slideUp().promise()
          .then =>
            @ui.scanPolicyShares.slideDown()

    @ui.scanMode.on "change", (event) =>
      if $(event.currentTarget).val() is "AllFolders"
        @ui.scanFilterPaths.slideUp()
      else
        @ui.scanFilterPaths.slideDown()

    @ui.useScanCredentials.on "change", (event) =>
      if $(event.currentTarget).is(":checked")
        @ui.credentials.slideUp()
      else
        @ui.credentials.slideDown()

    @ui.scheduleType.on "change", (event) =>
      value = $(event.currentTarget).val()

      switch value
        when 'Manual'
          @ui.scheduleDaily.slideUp()

        when 'Weekly'
          @ui.scheduleDaily.slideDown()
          @ui.scheduleWeekly.slideDown()
          @ui.scheduleMonthly.slideUp()

        when 'Daily'
          @ui.scheduleDaily.slideDown()
          @ui.scheduleWeekly.slideUp()
          @ui.scheduleMonthly.slideUp()

        when 'Monthly'
          @ui.scheduleDaily.slideDown()
          @ui.scheduleWeekly.slideUp()
          @ui.scheduleMonthly.slideDown()

        when 'Once'
          @ui.scheduleDaily.slideDown()
          @ui.scheduleWeekly.slideUp()
          @ui.scheduleMonthly.slideUp()


    @ui.scanPolicy.trigger "change"
    @ui.scanMode.trigger "change"
    @ui.scheduleType.trigger "change"
    @ui.useScanCredentials.trigger "change"

  cancel: (e) ->
    e.preventDefault()
    @options.cancel()

  save: (e) ->
    e.preventDefault()
    data = @serialize()
    @options.done?(data)
