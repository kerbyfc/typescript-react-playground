"use strict"

CollapseBehavior = require "behaviors/events/collapse.coffee"


module.exports = class EventProperties extends Marionette.ItemView

  className: 'eventDetail__propertiesWrap'

  template: 'events/event_views/event_properties'

  events:
    "click .tag__delete"        : "tags_delete"
    "click .drill_to_category"  : "drill_to_category"
    "click .drill_to_policy"    : "drill_to_policy"

  behaviors:
    EntityInfo:
      targets       : '.popover_info'
      behaviorClass : App.Behaviors.Events.EntityInfo
    Collapse:
      behaviorClass: CollapseBehavior

  templateHelpers: ->
    @service = @options.service

  drill_to_category: (e) ->
    e?.preventDefault()

    id = $(e.target).closest('.jquery-dropdown').data('id')
    App.Routes.Application.navigate "/analysis/#{id}/terms", {trigger: true}

  drill_to_policy: (e) ->
    e?.preventDefault()

    id = $(e.target).closest('.jquery-dropdown').data('id')
    App.Routes.Application.navigate "/policy/#{id}", {trigger: true}

  tags_delete: (e) ->
    e?.preventDefault()

    @model.deleteTags([$(e.currentTarget).data('tag-id')])
      .done @render
