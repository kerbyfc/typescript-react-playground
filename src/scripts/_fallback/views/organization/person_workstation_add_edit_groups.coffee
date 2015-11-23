"use strict"

require "layouts/dialogs/confirm.coffee"
require "controllers/organization.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

## Данный класс представляет из себя одну группу в форме редактирования персоны/рабочей станции

    class App.Views.Organization.PersonWorkstationAddEditGroup extends Marionette.ItemView

      template: "organization/person_workstation_add_edit_group"

      tagName : "li"

      className : "employeeExtendedItem"

      triggers:
        "click": 'selected'

      attributes: ->
        "data-selectable" : true
        "data-cid": @cid

      # onHighlightGroup : ->
      #   Organization.trigger "select:group:by:path",
      #     @model.get "ID_PATH"
      #     true

    # ## Данный класс представляет из себя группы в форме редактирования персоны/рабочей станции
    class App.Views.Organization.PersonWorkstationAddEditGroups extends Marionette.CompositeView

      LOCKED_GROUPS: ['ad', 'dd']

      template: "organization/person_workstation_add_edit_groups"

      childView: App.Views.Organization.PersonWorkstationAddEditGroup

      childViewContainer : "#person-workstation-groups"

      childViewOptions: ->
        personWorkstationItem: @options.personWorkstationItem

      triggers:
        "click [data-add-group]"    : "enter:in:group"
        "click [data-leave-group]"  : "leave:group"

      ui:
        add_group   : '[data-add-group]'
        leave_group : '[data-leave-group]'


      _blockToolbar: ->
        @ui.add_group.prop('disabled', true)
        @ui.leave_group.prop('disabled', true)


      _updateToolbar: ->
        @_blockToolbar()
        @ui.add_group.prop('disabled', false)
        selectedChildViews = @get_selected_views()

        leaveGroupDisabled = selectedChildViews.length is 0
        selectedChildViews.forEach (childView) =>
          if _.contains(@LOCKED_GROUPS,  childView.model.get('SOURCE'))
            leaveGroupDisabled = true

        @ui.leave_group.prop('disabled', leaveGroupDisabled)


      _makeSelectable: ->
        @$childViewContainer?.selectable
          filter : "[data-selectable]"


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


      onLeaveGroup: ->
        views = @get_selected_views()
        groups = _.map views, (view) -> view.model.get 'DISPLAY_NAME'

        App.Helpers.confirm
          title: App.t 'organization.leave_group'
          # data: do =>
          #   if (
          #     not @options.personWorkstationItem.isNew()  and
          #     @options.personWorkstationItem.get("groups").length is 1
          #   )
          #     locale = App.t('organization', { returnObjectTrees: true })
          #     type = locale[ @options.personWorkstationItem.collection.type ].toLowerCase()
          #     App.t 'organization.has_last_group',
          #       items : """
          #         #{ type }:
          #         "#{ contacts.join(', ') }"
          #       """
          #       type  : type
          data: "Вы действительно хотите удалить группы #{groups.join(', ')}?"
          accept: =>
            removed_groups = _.map views, (view) -> view.model

            groups = @options.personWorkstationItem.get("groups")
            groups.remove(
              removed_groups
            )

      # Открывается модальное окно с деровом групп для привязки к оной пользователя/рабочей станции
      onEnterInGroup: ->
        groups = _.map @options.personWorkstationItem.get("groups").models, (group) ->
          ID      : group.get 'GROUP_ID'
          TYPE    : 'group'
          NAME    : group.get 'DISPLAY_NAME'
          content : group

        App.modal2.show new App.Views.Controls.DialogSelect
          action   : "add"
          title    : App.t 'organization.chooseGroup'
          data     : groups
          items    : ['group']
          source   : 'tm'
          callback : (data) =>
            App.modal2.empty()

            @collection.add(_.map data[0], (group) -> group.content)
