"use strict"

helpers = require "common/helpers.coffee"
require "views/policy/policy.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}

    class App.Views.Policy.Content extends Marionette.CompositeView

      template: 'policy/content'

      templateHelpers: ->
        types: _.result @collection, 'types'

      childViewContainer: "@ui.list"

      childView: App.Views.Policy.Policy

      className: "content policy"

      behaviors: ->
        Role: [
          elements: [
            @ui.dropdown
          ]
          islock: ->
            return false if helpers.can { action: 'edit', type: 'policy_object' }
            return false if helpers.can { action: 'edit', type: 'policy_person' }
            true
          mode: "remove"
        ,
          elements: ["[data-type=OBJECT]"]
          islock: ->
            return false if helpers.can { action: 'edit', type: 'policy_object' }
            true
          mode: "remove"
        ,
          elements: ["[data-type=PERSON]"]
          islock: ->
            return false if helpers.can { action: 'edit', type: 'policy_person' }
            true
          mode: "remove"
        ]

      ui:
        list         : "[data-ui=list]"
        emptyPolicy  : "[data-ui=emptyPolicy]"
        dropdown     : ".dropdown"
        menu         : "[data-type=menu]"
        listFilter   : "[data-ui=filter]"
        buttonFilter : "[data-action=filter]"
        reset        : "[data-action=reset]"
        add          : "[data-action=addPolicy]"
        removeFilter : "[data-action=removeFilter]"

      collectionEvents:
        "add remove reset sync": ->
          if @collection.length
            @ui.emptyPolicy.hide()
          else
            @ui.emptyPolicy.show()

          _.each @collection.types(), (type) =>
            items = @collection.where TYPE: type
            $el = @$el.find "[data-block=#{type}]"
            if items.length
              $el.show().prev().show()
            else
              $el.hide().prev().hide()

      events:
        'click @ui.dropdown a': (e) ->
          e.preventDefault()
          @ui.menu.toggle()

        "click @ui.add": (e) ->
          e.preventDefault()
          type = $(e.target).data "type"

          if type is 'OBJECT'
            # сразу создаем модель политики защиты данных
            return @collection.create DATA: ITEMS: [],
              wait: true
              success: (model) ->
                Module.trigger "policy:item:select", model, "Policy"

          items = App.Models.Policy.PolicyItem::getObjectTypes.call @, type

          App.modal.show new App.Views.Controls.DialogSelect
            action                 : "create"
            type                   : "policy"
            title                  : App.t "entry.policy.add_objects", context: 'person'
            checkbox               : false
            preventSubmitDisabling : false
            data                   : []
            items                  : items

            onCancel: ->
              Module.trigger "policy:item:select", null, "Content"

            callback: (data) =>
              App.entry.add _.pluck(data[0], 'content')
              App.modal.empty()

              @collection.create DATA: ITEMS: data[0],
                wait: true
                success: (model) ->
                  Module.trigger "policy:item:select", model, "Policy"

        "click @ui.buttonFilter": ->
          Module.trigger "policy:sidebar:filter", @

        "click @ui.reset": ->
          Module.trigger "policy:filter:reset", @

        "click @ui.removeFilter": (e) ->
          filter = Module.filter
          return unless filter

          ID   = $(e.target).data "id"
          TYPE = $(e.target).data "type"

          if TYPE is "policy"
            item = _.where filter.name, ID: ID

            if item?.length
              filter.name = _.without filter.name, item[0]
          else
            item = _.where filter.object,
              ID   : ID
              TYPE : TYPE

            if item?.length
              filter.object = _.without filter.object, item[0]

          Module.trigger "policy:filter:apply", @
          Module.trigger "policy:sidebar:filter", @

      attachHtml: (cv, iv) ->
        type = iv.model.get 'TYPE'

        el = @getChildViewContainer(@).find "[data-block=#{type}]"
        el.prepend iv.el if el.length
