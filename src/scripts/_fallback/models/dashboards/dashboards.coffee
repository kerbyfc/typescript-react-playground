"use strict"

exports.Model = class DashboardItem extends App.Common.ValidationModel

  idAttribute: "DASHBOARD_ID"

  type: 'dashboard'

  urlRoot: "#{App.Config.server}/api/dashboard"

  validation:
    DISPLAY_NAME: [
      {
        minLength: 1
        msg: App.t 'dashboards.dashboards.display_name_validation_error'
      }
    ]

  islock: (data) ->
    data = action: data if _.isString data

    super data

exports.Collection = class Dashboards extends Backbone.Collection

  model: exports.Model

  url: "#{App.Config.server}/api/dashboard"

  comparator: (model) ->
    model.get "POSITION"

  initialize: (models, options = {}) ->
    {
      its_all: its_all
    } = options

    # Если это основная модель
    unless its_all
      # То в ней создаётся надмножество,
      # из которого можно выцепить скрытые и расшаренные дашборды
      @dashboards_all = new exports.Collection(
        []
        its_all: true
      )
      @dashboards_all.fetch()

      # Синхронизация основной модели с надмножеством
      @on "all", (event_name, model) ->
        interested_us = [
          "add"
          "destroy"
          "change"
        ]

        unless _.contains(interested_us, event_name)
          return

        switch event_name
          when "destroy"
            @dashboards_all.remove(
              @get model.id
            )

          when "add"
            @dashboards_all.add model

          when "change"
            @dashboards_all.get(
              model.id
            )
            .set(
              model.toJSON()
            )

  save_reorder: (ids) ->
    pick_id = (id) =>
      _.pick(
        @get(id).toJSON()

        @model::idAttribute
        "POSITION"
      )

    data = _.map(
      ids
      (id) -> pick_id(id)
    )

    @save(
      data
      type: "SORT"
    )
