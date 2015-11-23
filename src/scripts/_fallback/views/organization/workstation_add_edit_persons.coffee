"use strict"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

## Данный класс представляет из себя одну персону в форме редактирования рабочей станции

    class App.Views.Organization.WorkstationAddEditPerson extends Marionette.ItemView

      template: "organization/workstation_add_edit_person"

      tagName : "li"

      className : "employeeExtendedItem"

      triggers:
        "click"         : 'selected'

      attributes: ->
        "data-selectable" : true
        "data-cid": @cid

      # onWorkstationLeavePerson: ->
      #   App.Helpers.confirm
      #     title: App.t 'organization.leavePerson'
      #     accept: =>
      #       @options.workstation.get("persons").remove @model


## Данный класс представляет из себя коллекцию персон в форме редактирования рабочей станции

    class App.Views.Organization.WorkstationAddEditPersons extends Marionette.CompositeView

      template: "organization/workstation_add_edit_persons"

      childView: App.Views.Organization.WorkstationAddEditPerson

      childViewContainer: "#workstation_persons"

      childViewOptions: ->
        workstation: @options.workstation

      ui:
        add_person     : '[data-add-person ]'
        delete_person  : '[data-delete-person]'

      triggers:
        "click [data-add-person]"     : "add:person:to:workstation"
        "click [data-delete-person]"  : "delete:person:from:workstation"

      _makeSelectable: ->
        @$childViewContainer?.selectable
          filter : "[data-selectable]"

      onRenderCollection: ->
        @_makeSelectable()

      onAddChild: ->
        @_makeSelectable()

        @_updateToolbar()

      _bloackToolbar: ->
        @ui.add_person.prop('disabled', true)
        @ui.delete_person.prop('disabled', true)

      onChildviewSelected: ->
        @_updateToolbar()

      _updateToolbar: ->
        @_bloackToolbar()

        selected = @get_selected_views()

        @ui.add_person.prop('disabled', false)

        if selected.length
          @ui.delete_person.prop('disabled', false)

      onShow: ->
        @_updateToolbar()

      get_selected_views : ->
        _ @$ ".ui-selected"
        .map (el) =>
          @$childViewContainer.find el
          .data('cid')
        .map (cid) =>
          @children.findByCid cid
        .value()

      onDeletePersonFromWorkstation: ->
        views = @get_selected_views()

        persons = _.map views, (view) -> view.model.get 'DISPLAY_NAME'

        App.Helpers.confirm
          title: App.t 'organization.leavePerson'
          data: "Вы действительно хотите удалить персоны #{persons.join(', ')}?"
          accept: =>
            removed_persons = _.map views, (view) -> view.model

            persons = @options.workstation.get("persons")
            persons.remove(
              removed_persons
            )

      onAddPersonToWorkstation: ->
        persons = _.map @options.workstation.get("persons").models, (person) ->
          ID      : person.get 'PERSON_ID'
          TYPE    : 'person'
          NAME    : person.get 'DISPLAY_NAME'
          content : person

        App.modal2.show new App.Views.Controls.DialogSelect
          action   : "edit"
          title    : App.t 'organization.add_person'
          data     : persons
          items    : ['person']
          source   : 'tm'
          callback : (data) =>
            App.modal2.empty()

            @collection.reset(_.map data[0], (person) -> person.content)
