"use strict"

helpers = require "common/helpers.coffee"
require "backbone.syphon"

require "models/organization/contacts.coffee"
require "views/organization/contacts.coffee"
require "behaviors/organization/ad_tm_name.coffee"

module.exports = class AddEditGroups extends Marionette.LayoutView

  template : "organization/groups_add_edit"

  triggers:
    "click [data-action=save]" : "add:edit:group"

  regions:
    contactsRegion: "#unit_tabs--group-contacts"

  ui:
    childrens       : "#unit_tabs--group-childrens > ul"
    parents         : "#unit_tabs--group-parents > ul"
    tabs_links      : "[data-toggle=tab]"

  behaviors :
    "ad_tm_name" :
      behaviorClass : App.Behaviors.Organization.ADTMName


  initialize: (options) ->
    @model = @collection.get @options.parentGroupId
    @contactsView = new App.Views.Organization.Contacts(
      blocked: options.blocked
      collection: do =>
        if @options.mode is "add"
          @model = new @collection.model()
          new App.Models.Organization.Contacts [], type : "group"
        else if @options.mode is "edit"
          @model.get "contacts"
    )


  serializeData : ->
    _.extend {}, super, @options


  onShow: ->
    @contactsRegion.show @contactsView
    if @options.mode is "edit"
      Backbone.Syphon.deserialize @, @model.toJSON()

    if not @model.isNew()
      @_render_related_groups()
      @_remove_animations_in_related_groups()


  onAddEditGroup : ->
    unless helpers.can({ action: "edit", type: "group" })
      return

    if @options.mode is "add"
      @collection.create(
        _.extend(
          Backbone.Syphon.serialize(@)
          parents  : [GROUP_ID : @options.parentGroupId]
          SOURCE   : "tm"
          contacts : @contactsView.collection.toJSON()
        ),
        success : => @destroy()
        error: (model, response) ->
          _.each response.responseJSON, (error_causes, field) ->
            if "not_unique_field" in error_causes
              App.Notifier.showError
                text: App.t 'organization.group_exists'
            if field is "DISPLAYNAME" and
                "required" in error_causes

              App.Notifier.showError
                text: App.t 'organization.group_hasnt_displayname'

        wait: true
      )
    else if @options.mode is "edit"
      @model.save(
        _.extend @model.toJSON(),
          contacts : _.filter @model.get("contacts").toJSON(), (contact_data) ->
            not contact_data.creator
          Backbone.Syphon.serialize @
        wait  : true
        success : => @destroy()
        error : (model, xhr) ->
          if(
            _.isArray( xhr.responseJSON?.DISPLAY_NAME )  and
            "not_unique_field" in xhr.responseJSON.DISPLAY_NAME
          )
            App.Notifier.showError
              text : App.t 'organization.group_exists'
      )

  _reanimate_tabs: ->
    @ui.tabs_links.tab "show"
    @ui.tabs_links.eq(0).click()

  _render_related_groups: ->
    for $tab_content in [@ui.childrens, @ui.parents]
      rendered = (
        for item in _.sortBy(
          @model.get $tab_content.data "model-attr"
          "NAME_PATH"
        )
          """
            <li>
              #{
                Marionette.Renderer.render(
                  "organization/person_workstation_add_edit_group"
                  item
                )
              }
            </li>
          """
      ).join("")
      $tab_content.html rendered
    @_reanimate_tabs()

  _remove_animations_in_related_groups: ->
    for el in (
      @ui.childrens.add @ui.parents
      .find ".animation--block"
    )
      el.remove()
