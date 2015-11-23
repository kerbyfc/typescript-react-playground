"use strict"

App.module "Organization",
  startWithParent : false
  define        : (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

    class PersonWorkstationStatus extends Marionette.ItemView

      # ****************
      #  MARIONETTE
      # ****************
      template      : "organization/person_workstation_add_edit_status"

      className     : "employeeExtendedItem"

      tagName       : "li"

      attributes: ->
        "data-selectable" : true
        "data-cid"        : @cid

      triggers:
        "click"           : 'selected'

      templateHelpers : ->
        get_add_note : ->
          if @ADD_NOTE?.match /^_.+_$/
            [assigner_type, assigner_value...] =
              @ADD_NOTE
              .replace /^./, ""
              .replace /.$/, ""
              .split "_"

            if $.i18n.exists "lists.statuses.auto_status_#{ assigner_type }"
              App.t "lists.statuses.auto_status_#{ assigner_type }",
                value : assigner_value.join "_"
            else
              App.t "lists.statuses.#{ @NOTE }note"
          else if @ADD_NOTE?
            @ADD_NOTE
          else
            ""
        type   : Organization.reqres.request("get:content:entity:type")[1]

    class App.Views.Organization.PersonWorkstationAddEditStatuses extends Marionette.CompositeView

      # ****************
      #  MARIONETTE
      # ****************
      childView : PersonWorkstationStatus

      childViewContainer : "#person_workstation_statuses"

      childViewOptions: -> personWorkstationItem: @options.personWorkstationItem

      template : "organization/person_workstation_add_edit_statuses"

      triggers :
        "click [data-add-status]"     : "manage:statuses"
        "click [data-delete-status]"  : "delete:statuses"

      ui:
        add_status    : '[data-add-status]'
        delete_status : '[data-delete-status]'

      templateHelpers  : ->
        type : Organization.reqres.request("get:content:entity:type")[1]

      _makeSelectable: ->
        @$childViewContainer?.selectable
          filter : "[data-selectable]"

      _blockToolbar: ->
        @ui.add_status.prop('disabled', true)
        @ui.delete_status.prop('disabled', true)

      _updateToolbar: ->
        @_blockToolbar()

        selected = @get_selected_views()
        has_system = _.filter selected, (view) -> view.model.get('EDITABLE') is 0

        @ui.add_status.prop('disabled', false)

        if selected.length and has_system.length is 0
          @ui.delete_status.prop('disabled', false)

      onRenderCollection: ->
        @_makeSelectable()

      onRemoveChild: ->
        @_updateToolbar()

      onAddChild: ->
        @_makeSelectable()

        @_updateToolbar()

      onShow: ->
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

      onDeleteStatuses: ->
        views = @get_selected_views()

        statuses = _.map views, (view) -> view.model.get 'DISPLAY_NAME'

        App.Helpers.confirm
          title: App.t "#{ App.t "global.delete" }?"
          data: "Вы действительно хотите удалить статусы #{statuses.join(', ')}?"
          accept: =>
            removed_statuses = _.map views, (view) -> view.model

            statuses = @options.personWorkstationItem.get("status")
            statuses.remove(
              removed_statuses
            )

      onManageStatuses : ->
        Organization.trigger "set:status:person:workstation:item", true
