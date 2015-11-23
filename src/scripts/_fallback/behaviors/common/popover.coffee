"use strict"

entry = require "common/entry.coffee"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Popover extends Marionette.Behavior

  onRender: ->
    _.each @options, (o) =>

      _.each o.elements, (el) =>
        $el = if _.isString el then @$ el else $ el
        return if not $el.length

        $el
        .attr 'data-popover-el', ''
        .data 'popoverContent', o.content

        $el.data 'popoverTitle', o.title if o.title
        $el.data 'popoverTemplate', o.template if o.template
