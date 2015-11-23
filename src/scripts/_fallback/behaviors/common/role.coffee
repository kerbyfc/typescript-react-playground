"use strict"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Role extends Marionette.Behavior

  onRender: ->
    _.each @options, (o) =>
      status = if _.isString o.islock then o.islock else o.islock()
      return unless status
      mode = switch o.mode
        when "remove"
          (el) ->
            el.remove()
        when "disabled"
          (el) ->
            el.prop "disabled", true
            .attr "data-role-state", "disabled"
        when "hide"
          (el) ->
            el
            .hide()
            .attr "data-role-state", "hide"
        when "readonly"
          (el) ->
            el
            .prop "readonly", true
            .attr "data-role-state", "readonly"
        else
          o.mode

      _.each o.elements, (el) =>
        el = if _.isString el then $ el, @$el else $ el
        return if not el.length
        mode el
