"use strict"

require "bootstrap"

Selections = require "models/events/selections.coffee"
FilterView = require "views/events/query_builder/filter_view.coffee"

conditions = require "settings/conditions"

module.exports = class AdvancedConditionsDialog extends Marionette.LayoutView

  template: "events/query_builder/condition"

  filterView: FilterView

  regions:
    'conditions': '#condition'

  className: "queryBuilder"

  events:
    'click ._success'  : 'save'

  templateHelpers: ->
    title: @options.title

  defaults:
    conditions: conditions

  initialize: (options) ->
    _.extend @options, _.defaults options, @defaults

  onShow: ->
    data = @options.model.get('QUERY').data
    conditions = new Selections.TreeNode data

    @listenTo conditions, 'change', =>
      query = @options.model.get('QUERY')
      query.data = conditions.toJSON()
      @options.model.set 'QUERY', query

      @model.trigger 'change', @model, {}

    options = _.extend {}, @options,
      model: conditions
      formats: App.request 'bookworm', 'fileformat'

    @conditions.show(new @filterView(options))

