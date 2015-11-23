"use strict"

require "bootstrap.daterangepicker"

exports.WidgetView = class WidgetView extends Marionette.LayoutView

  constructRanges: ->
    @RANGES =
      this_day     : [moment().startOf('day'), moment().endOf('day')],
      last_3_days  : [moment().subtract('days', 3).endOf('day'), moment().endOf('day')],
      last_7_days  : [moment().subtract('days', 7).endOf('day'), moment().endOf('day')],
      this_week    : [moment().startOf('week').startOf('day'), moment().endOf('week').endOf('day')],
      this_month   : [moment().startOf('month').startOf('day'), moment().endOf('month').endOf('day')],
      last_30_days : [moment().subtract('days', 29).endOf('day'), moment().endOf('day')]

    dict = {}
    locale = App.t('dashboards.widgets', { returnObjectTrees: true })

    for key, value of @RANGES
      dict[locale[key]] = value

    dict

  onRender: ->
    @$el.find('.rule_type').select2
      minimumResultsForSearch: Infinity
      placeholder: ' '

    @$el.find('.rule_type').on "change", (e) =>
      rule_type = $(e.target).val()

      @collection.RULE_GROUP_TYPE = rule_type

      @collection.filter = {}

      if rule_type isnt ''
        @collection.filter = filter:
          RULE_GROUP_TYPE: rule_type

      @collection.fetch
        reset: true
        wait: true

    if @$el.find('#reportrange').data('daterangepicker')
      @$el.find('#reportrange').data('daterangepicker').remove()

    if @$el.find('#reportrange span').html() is ''
      @$el.find('#reportrange span').html(@collection?.start_date?.format("L") + ' - ' + @collection?.end_date?.format("L"))

    @$el.find('#reportrange').daterangepicker(
      {
        format                : "L"
        opens                 : if @model.get('COL') is '0' then 'right' else 'left'
        startDate             : @collection?.start_date
        endDate               : @collection?.end_date
        locale                : App.t 'daterangepicker', returnObjectTrees: true
        ranges                : @constructRanges()
      },
      (start, end) =>
        @$el.find('#reportrange span').html(start.format("L") + ' - ' + end.format("L"))

        @collection.start_date = start
        @collection.end_date = end

        @collection.currentPage = 0

        @collection.fetch
          reset: true
    )


exports.WidgetSettings = class WidgetSettings extends Marionette.ItemView

  behaviors: ->
    Form:
      listen : @options.model
      syphon : true
