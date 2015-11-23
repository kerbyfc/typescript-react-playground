"use strict"

require "webui-popover"

require "views/organization/persons.coffee"
require "models/organization/persons.coffee"
require "models/organization/groups.coffee"

App.Behaviors.Events ?= {}

class App.Behaviors.Events.EntityInfo extends Marionette.Behavior

  onDestroy: ->
    @view.$(@options.targets).webuiPopover('destroy')

  onRender: ->
    @_attachPopovers()

  _attachPopovers: ->

    @view.$(@options.targets).webuiPopover
      placement     : 'auto-bottom'
      closeable     : true
      width         : 300
      content       : ->
        $element    = $(@)
        type        = $element.data('type')

        switch type
          when 'perimeter'
            model = new Backbone.Model
              id        : $element.data('id')
              keys      : $element.data('keys')
              name      : $element.data('name')

            view = new Marionette.ItemView
              template: 'events/dialogs/perimeter_info'
              model: model

            view.render()

          when 'person'
            id          = $element.data('id')
            object_id   = $element.data('object')
            direction   = $element.data('direction')

            data        = {}

            if object_id
              data["#{direction}_object_id"] = object_id

            model = new App.Models.Organization.Person({PERSON_ID: id})
            if direction
              model.set('direction', direction)

            view = new Marionette.ItemView
              template: 'events/dialogs/person_info'
              model: model

            model.fetch
              data: data
              success: ->
                view.render()
              error: ->
                throw new Error("Can't load user info")

          when 'group'
            id          = $element.data('id')
            object_id   = $element.data('object')
            direction   = $element.data('direction')

            data        = {}
            data["#{direction}_object_id"] = object_id

            model = new App.Models.Organization.Group({GROUP_ID: id})
            model.set('direction', direction)

            view = new Marionette.ItemView
              template: 'events/dialogs/group_info'
              model: model

            model.fetch
              data: data
              success: ->
                view.render()
              error: ->
                throw new Error("Can't load group info")

          when 'workstation'
            id          = $element.data('id')
            object_id   = $element.data('object')

            data        = {}
            data["workstation_object_id"] = object_id

            model = new App.Models.Organization.Workstation({WORKSTATION_ID: id})
            model.set('direction', direction)

            view = new Marionette.ItemView
              template: 'events/dialogs/workstation_info'
              model: model

            model.fetch
              data: data
              success: ->
                view.render()
              error: ->
                throw new Error("Can't load workstation info")

        return view.$el
