"use strict"

require "jquery.dashboard"
helpers = require "common/helpers.coffee"

WidgetsModels = require "models/dashboards/widgets.coffee"
StatTypes = require "models/dashboards/stattype.coffee"

StatTypeWidgets =
  1: require "views/dashboards/renderers/threats.coffee"
  2: require "views/dashboards/renderers/users.coffee"
  3: require "views/dashboards/renderers/threats_stats.coffee"
  4: require "views/dashboards/renderers/selection_stats.coffee"
  5: require "views/dashboards/renderers/status_stats.coffee"
  6: require "views/dashboards/renderers/policy_stats.coffee"
  7: require "views/dashboards/renderers/protected_document_stats.coffee"
  8: require "views/dashboards/renderers/protected_catalog_stats.coffee"


class WidgetItem extends Marionette.LayoutView

  tagName: "li"

  className: 'jdash-widget'

  template: "dashboards/widgets/widget"

  regions:
    widgetContent: '[data-region="content"]'
    widgetSettings: '[data-region="settings"]'

  triggers:
    "click .js-remove-dashboard-widget"     : "remove:widget"
    "click .js-widget-settings"             : "setup:widget"
    "click .tm-complete-setup-widget"       : "complete:setup:widget"
    "click .tm-cancel-setup-widget"         : "cancel:setup:widget"

  templateHelpers: ->
    locale: App.t 'dashboards.widgets', { returnObjectTrees: true }

  _flip_front: ->
    @$el.find('> :first-child').removeClass('flipped')

  _flip_back: ->
    @$el.find('> :first-child').addClass('flipped')

  _setTimer: ->
    @_clearTimer()

    if @model.get("BASEOPTIONS") and @model.get("BASEOPTIONS").periodUpdate
      @timer = setInterval =>
        @render()
      , @model.get("BASEOPTIONS").periodUpdate * 60000

  _clearTimer: ->
    clearInterval @timer if @timer
    @timer = null

  _hide_errors: ->
    for elem in @$('input')
      $(elem).popover("destroy") if $(elem).data("bs.popover")

  _showErrorHint: (error, element) ->
    elem = @$(element)

    elem.popover("destroy") if elem.data("bs.popover")

    position = elem.data("tooltip-position") or "top"

    elem.popover(
      placement: position
      trigger: "manual"
      content: error
      container: elem.closest(".back")
    )
    elem.popover('show')

  serialize: ->
    data = super
    if data.BASEOPTIONS?.default_period in ['from', 'to']
      data.BASEOPTIONS.default_period = 'period'
    data

  onDestroy: ->
    @_clearTimer()

  onRender: ->
    @stat_type = @model.get 'STATTYPE_ID'

    if StatTypeWidgets[@stat_type]?.WidgetView
      @widgetContent.show new StatTypeWidgets[@stat_type].WidgetView
        model: @model

    if StatTypeWidgets[@stat_type]?.WidgetSettings
      @widgetSettings.show new StatTypeWidgets[@stat_type].WidgetSettings
        model: @model
        stattype: @options.stattypes.get @stat_type

  initialize: ->
    @statType = @options.stattypes.get(@model.get("STATTYPE_ID"))

    @on "setup:widget", =>
      @_flip_back()

      # Отключаем обновление пока мы в настройках
      @_clearTimer()

    @on 'cancel:setup:widget', =>

      @_hide_errors()

      @$el.find('> :first-child > :first-child').one "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", =>
        @$el.find('> :first-child > :first-child').off "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd"

        @widgetSettings.reset()

        @widgetSettings.show new StatTypeWidgets[@stat_type].WidgetSettings
          model: @model
          stattype: @options.stattypes.get @stat_type

        @_setTimer()

      @_flip_front()

    @on "complete:setup:widget", =>
      data = @serialize()

      # Скрываем все ошибки
      @_hide_errors()

      if validate = @widgetContent.currentView.validateVidgetSettings
        validationResult = validate(@statType.get('STAT'), @)

        if not _.isEmpty validationResult
          for elem, error of validationResult
            @_showErrorHint error, "[name='BASEOPTIONS[#{elem}]']"

          return

      # Вставляем небольшую задержку чтобы успели скрытся popover и анимация выглядела более плавно
      _.delay =>
        # Отписываемся т.к. Chrome реагирует на несколько событий
        @$el.find('> :first-child > :first-child').on "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", =>
          @$el.find('> :first-child > :first-child').off "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd"

          @model.save data,
            wait: true
            success: =>
              @render()

              @_setTimer()

        @_flip_front()
      , 300

    @_setTimer()

module.exports = class Widgets extends Marionette.CollectionView

  className: 'jdash'

  tagName: 'ul'

  childViewOptions: ->
    return {
      stattypes: @stattypes
    }

  childView: WidgetItem

  serealizeWidgets: ->
    positions = _.map @$el.find('.jdash-widget'), (widget) ->
      "#{$(widget).attr('id')}:#{$(widget).closest('.jdash-column').data('column')}:#{$(widget).index()}"

    _.each (_.difference positions, @positions), (widget) =>
      [id, col, line] = widget.split(':')

      @collection.get(id).save
        LINE  : line
        COL   : col

    @positions = positions

  attachHtml: (collectionView, childView) ->
    childView.$el.attr('id', childView.model.get('DASHBOARD_WIDGET_ID'))

    element =
      @$el
      .find(".jdash-column[data-column='#{childView.model.get('COL')}']")
      .children("li:eq(#{childView.model.get('LINE')})")

    if element.length is 0
      @$el.find(".jdash-column[data-column='#{childView.model.get('COL')}']").append(childView.el)
    else
      element.before(childView.el)

    if helpers.can({action: 'edit', type: 'dashboard'})
      @$el.dashboard('addWidget', childView.$el)

  attachBuffer: ->

  initialize: ->
    @collection = new WidgetsModels.Collection()
    @stattypes ?= new StatTypes.Collection()
    @collection.dashboard = @model

    @collection.fetch
      data:
        filter:
          DASHBOARD_ID:
            @model.get 'DASHBOARD_ID',
      reset: true
      wait: true

    @on "childview:remove:widget", (view) =>
      locale = App.t 'dashboards', { returnObjectTrees: true }
      widgetName = view.model.getName() or locale.widgets["#{view.statType.get('STAT')}_name"]

      dashboardName = App.Helpers.getPredefinedLocalizedValue @options.model.get('DISPLAY_NAME'), 'dashboards.dashboards'

      App.Helpers.confirm
        title: App.t "dashboards.widgets.delete_dialog_title"
        data: App.t "dashboards.widgets.delete_dialog_question",
          widgetName: widgetName
          dashboardName: dashboardName
        accept: =>
          view.model.destroy
            success: =>
              @serealizeWidgets()
              @trigger 'item:remove'

    @on "item:add", =>
      @serealizeWidgets()

  onRenderCollection: ->
    @positions = _.map @$el.find('.jdash-widget'), (widget) ->
      "#{$(widget).attr('id')}:#{$(widget).closest('.jdash-column').data('column')}:#{$(widget).index()}"

  drawLayout: ->
    switch @model.get('LAYOUT')
      when 1
        for num in [0..2]
          column = $("<ul class='jdash-column dashboard__col_one-third' data-column='#{num}'></ul>")
          @$el.append column
      when 2
        column = $("<ul class='jdash-column dashboard__col_two-thirds' data-column='0'></ul>")
        @$el.append column
        column = $("<ul class='jdash-column dashboard__col_one-third' data-column='1'></ul>")
        @$el.append(column)
      when 3
        column = $("<ul class='jdash-column dashboard__col_half' data-column='0'></ul>")
        @$el.append column
        column = $("<ul class='jdash-column dashboard__col_half' data-column='1'></ul>")
        @$el.append(column)
      when 4
        column = $("<ul class='jdash-column dashboard__col_one-third' data-column='0'></ul>")
        @$el.append column
        column = $("<ul class='jdash-column dashboard__col_two-thirds' data-column='1'></ul>")
        @$el.append(column)
      else
        column = $("<ul class='jdash-column dashboard__col_two-thirds' data-column='0'></ul>")
        @$el.append column
        column = $("<ul class='jdash-column dashboard__col_one-third' data-column='1'></ul>")
        @$el.append(column)

  onDomRefresh: ->
    if helpers.can({action: 'edit', type: 'dashboard'})
      @dashboard = @$el.dashboard
        widgetClass: '.jdash-widget'
        columnClass: '.jdash-column'
        sectorClass: '.jdash-sector'
        headerClass: '.widget__header .handle'
        toolbarClass: '.widget__actions'
        container: '.layout__content'
        draggingClass: 'jdash_dragging'
        onMoved: (widget_id) =>
          @children.findByModel(@collection.get widget_id).render()

          @serealizeWidgets()

  onBeforeRender: (collectionView) ->
    @$el.empty()
    @drawLayout()

    if collectionView.collection.length > 0
      collectionView.collection.sort
        silent: true

      colCount = if collectionView.model.get('LAYOUT') is 1 then 2 else 1
      col  = 0
      line = 0
      collectionView.collection.each (model) ->
        if col - colCount > 0
          col = 0
          line++

        model.set
          COL: col
          LINE: line

        col++

  onRender: ->
    @$el.append('<div class="jdash-sector"></div>')
