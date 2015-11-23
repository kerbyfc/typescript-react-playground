"use strict"

require "models/organization/groups.coffee"
require "views/controls/tree_view.coffee"

App.module "Dashboards.Dialogs",
  startWithParent: true
  define: (Dashboards, App, Backbone, Marionette, $) ->

    App.Views.Dashboards ?= {}

    class App.Views.Dashboards.SelectGroupDialog extends App.Views.Controls.TreeView

      template: "dashboards/dialogs/select_groups"

      config:
        locale      : App.t('organization', { returnObjectTrees: true })
        sorting     : true
        checkbox    : true
        selectMode    : 3
        data_key_path : "GROUPPATH"
        dataKeyTitle  : "grouppath"
        dataKeyField  : "GROUP_ID"
        dataLoadField : "GROUPPATH"
        dataChildsField : "childsCount"
        dataParentField : "PARENT_GROUP_ID"
        dataTextField : "DISPLAY_NAME"
        dataIconField : (group_data) ->
          if group_data.GROUP_TYPE is "adlibitum"
            "server"
          else if (
            group_data.GROUP_TYPE is "adGroup"  and
              group_data.SOURCE is "dd"
          )
            group_data.SOURCE
          else
            group_data.GROUP_TYPE
        dataUnselectableFields  : (elem) ->
          elem.GROUP_TYPE is 'adlibitum'
        icons:
          "ad"      : "icon-ad"
          "adGroup"   : "icon-ad_group"
          "adDomain"    : "icon-ad_domain"
          "adOU"      : "icon-ad_ou"
          "adContainer" : "icon-ad_container"
          "dd"      : "icon-dd"
          "server"    : "icon-server"
          "tmGroup"   : "icon-tm_group"
          "tmRoot"    : "icon-tm_root"

      events:
        "click .-success": "save"

      initialize: (options) ->
        @callback = options.callback
        @title = options.title
        @selected = options.selected

        @collection = new App.Models.Organization.Groups()

      save: (e) ->
        e.preventDefault()

        @callback(@getChecked())

        @destroy()

      onShow: ->
        @$el.i18n()

        @on "treeview:postinit", =>
          _.each @selected, (id) =>
            @collection.fetchOne id, {}, (model) =>
              @select
                path: model.get('GROUPPATH')

        @collection.fetch
          reset: true


      serializeData: ->
        data = Marionette.ItemView::serializeData.apply @, arguments

        # Добавляем название диалога и кнопки
        data.modal_dialog_title = @title

        data
