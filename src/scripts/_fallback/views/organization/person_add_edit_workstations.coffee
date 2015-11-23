"use strict"

require "layouts/dialogs/confirm.coffee"

App.module "Organization",
    startWithParent: false
    define: (Organization, App, Backbone, Marionette, $) ->

      App.Views.Organization ?= {}

## Данный класс представляет из себя одну рабочую станцию в форме редактирования персоны

      class App.Views.Organization.PersonAddEditWorkstation extends Marionette.ItemView

        template: "organization/person_add_edit_workstation"

        tagName : "li"

        className : "employeeExtendedItem"

        triggers:
          "click"         : 'selected'

        attributes: ->
          "data-selectable" : true
          "data-cid": @cid

## Данный класс представляет из себя коллекцию рабочих станций в форме редактирования персоны

      class App.Views.Organization.PersonAddEditWorkstations extends Marionette.CompositeView

        template: "organization/person_add_edit_workstations"

        childView: App.Views.Organization.PersonAddEditWorkstation

        childViewContainer: "#person_workstations"

        ui:
          add_workstation     : '[data-add-workstation ]'
          delete_workstation  : '[data-delete-workstation]'

        triggers:
          "click [data-add-workstation]"    : "add:workstations:to:person"
          "click [data-delete-workstation]" : "delete:workstation:from:person"

        _makeSelectable: ->
          @$childViewContainer?.selectable
            filter : "[data-selectable]"

        _updateToolbar: ->
          @_bloackToolbar()

          selected = @get_selected_views()

          @ui.add_workstation.prop('disabled', false)

          if selected.length
            @ui.delete_workstation.prop('disabled', false)

        _bloackToolbar: ->
          @ui.add_workstation.prop('disabled', true)
          @ui.delete_workstation.prop('disabled', true)

        onRenderCollection: ->
          @_makeSelectable()

        onShow: ->
          @_updateToolbar()

        onAddChild: ->
          @_makeSelectable()

          @_updateToolbar()

        onChildviewSelected: ->
          @_updateToolbar()

        get_selected_views : ->
          _ @$ ".ui-selected"
          .map (el) =>
            @$childViewContainer.find el
            .data('cid')
          .map (cid) =>
            @children.findByCid cid
          .value()

        onDeleteWorkstationFromPerson: ->
          views = @get_selected_views()

          workstations = _.map views, (view) -> view.model.get 'DISPLAY_NAME'

          App.Helpers.confirm
            title: App.t 'organization.leaveWorkstation'
            data: "Вы действительно хотите удалить рабочие станции #{workstations.join(', ')}?"
            accept: =>
              removed_workstations = _.map views, (view) -> view.model

              workstations = @options.person.get("workstations")
              workstations.remove(
                removed_workstations
              )

        onAddWorkstationsToPerson: ->
          workstations = _.map @options.person.get("workstations").models, (workstation) ->
            ID      : workstation.get 'WORKSTATION_ID'
            TYPE    : 'workstation'
            NAME    : workstation.get 'DISPLAY_NAME'
            content : workstation

          App.modal2.show new App.Views.Controls.DialogSelect
            action   : "edit"
            title    : App.t 'organization.add_workstation'
            data     : workstations
            items    : ['workstation']
            source   : 'tm'
            callback : (data) =>
              App.modal2.empty()

              @collection.reset(_.map data[0], (workstation) -> workstation.content)
