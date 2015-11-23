"use strict"

co = require "co"
async = require "async"
helpers = require "common/helpers.coffee"

require "models/organization/groups.coffee"
require "views/controls/tree_view.coffee"
GroupsView = require "layouts/organization/groups_add_edit.coffee"
require "layouts/dialogs/confirm.coffee"


App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

    class App.Views.Organization.Groups extends App.Views.Controls.TreeView

      # *************
      #  PRIVATE
      # *************
      _is_big_nested_level = (model, size) ->
        if (
          _.compact(
            model.get "ID_PATH"
            .split "\\"
          )
          .length > size
        )
          App.Notifier.showWarning
            text : App.t "organization.group_big_nested_level"

      _highlight_finded = (result, query) ->
        result.replace(
          new RegExp query, "i"
          (finded) ->
            "<span class=label-warning>#{ finded }</span>"
        )

      _render_ldap_sync = (collection, nodes) ->
        _.each nodes, (node) ->
          if (
            ldap_status =
              collection.get node.key
              .get_ldap_sync()
          )
            node.span.title = App.Views.Organization.Groups.construct_ldap_title ldap_status

      _select_group_by_path = (path, silent_select, self = @) -> co ->
        node = yield self.load_node path
        self.collection.select (node)
        unless silent_select
          node.setActive(true)


        self.tree_view_container.scrollTop ( node.span.offsetTop - self.tree_view_container.position().top)

      _setup_search_by_groups = (self) ->
        self.ui.search
        .on "select2-selecting", (event) ->
          _select_group_by_path event.val, false, self
        .select2
          ajax :
            data  : (term) ->  filter : DISPLAY_NAME : "*#{ term }*"
            results : (resp) ->
              results :
                _.filter resp.data.contact, (by_contact) ->
                  not _.find resp.data.group, GROUP_ID : by_contact.IDENTITY_ID
                .concat resp.data.group

            url   : "#{ App.Config.server }/api/ldapGroup"

          formatResult : (result_item, $el, options) ->
            display_path =
              _highlight_finded(
                result_item.NAME_PATH ? result_item.group.NAME_PATH
                options.term
              )
              .replace "tmRoot",
                App.t "organization.tmRoot"
            contact_value =
              if result_item.CONTACT_TYPE
                _highlight_finded(
                  result_item.VALUE
                  options.term
                )

            []
            .concat """
              <i class=fontello-icon-users-1></i>
              #{ display_path }
            """
            .concat(
              switch result_item.CONTACT_TYPE
                when "email"
                  "<i class=i-unit-contact__mail></i> #{ contact_value }"
                when "lotus"
                  "<i class=i-unit-contact__lotus></i> #{ contact_value }"
                when "sid"
                  "<i class=fontello-icon-user-4></i> #{ contact_value }"
                else
                  []
            )
            .join "<br>"

          formatResultCssClass : -> "select2-group-search"
          formatSelection    : ->  @placeholder
          id            : (item) ->  item.ID_PATH ? item.group.ID_PATH
          minimumInputLength  : 3
          placeholder       : App.t "organization.search_by_groups"

      _toolbar_disable = (jq_els) ->
        _.invoke jq_els, "prop", "disabled", true

      _toolbar_enable = (jq_els) ->
        _.invoke jq_els, "prop", "disabled", false

      _toolbar_setup_visibility = (self, model, node) ->

        source = model.get "SOURCE"

        if source is "tm"
          if model.get('GROUP_TYPE') is "tmRoot"
            _toolbar_disable [self.ui.toolbar_all]
            _toolbar_enable [self.ui.toolbar_create]
          else
            _toolbar_enable [self.ui.toolbar_all]

        else if source in ["ad", "dd"]
          _toolbar_disable [self.ui.toolbar_all]

          if model.get("GROUP_TYPE") isnt "adRoot"
            _toolbar_enable [self.ui.toolbar_edit, self.ui.toolbar_export, self.ui.toolbar_import]

            parent_source =
              self.collection
              .get node.parent.key
              .get("SOURCE")
            if parent_source is "tm"
              _toolbar_enable [self.ui.toolbar_delete]

        unless helpers.can({action: 'delete', type: 'group'})
          _toolbar_disable [self.ui.toolbar_delete]

        unless helpers.can({action: 'edit', type: 'group'})
          _toolbar_disable [self.ui.toolbar_create, self.ui.toolbar_edit]

        if (
          helpers.can({action: 'edit', type: 'policy_object'}) and
          model.get("GROUP_TYPE") isnt "adRoot"
        )
          _toolbar_enable [self.ui.toolbar_policy]
        else
          _toolbar_disable [self.ui.toolbar_policy]


      # ************
      #  STATIC
      # ************
      @construct_ldap_title = (ldap_status) ->
        []
        .concat(
          """
            #{ App.t "settings.ldap_settings.sync_status" }: \
            #{ App.t "organization.ldap_state_#{ ldap_status.state }" }
          """
        )
        .concat(
          """
            #{ App.t "settings.ldap_settings.sync_date" }: \
            #{
              if ldap_status.timestamp is false
                App.t "settings.ldap_settings.sync_not_started"
              else
                ldap_status.timestamp
            }
          """
        )
        .concat(
          if ldap_status.state is "error"
            App.t "organization.ldap_error"
          else
            []
        )
        .join "<br>"


      # ****************
      #  MARIONETTE
      # ****************
      template: 'organization/groups'

      className: "sidebar__content"

      events:
        "click [data-action='create_group']"  : "add_node"
        "click [data-action='delete_group']"  : "delete_node"
        "click [data-action='edit_group']"    : "edit_node"
        "click [data-action='create_policy']" : "create_policy"

      ui:
        search          : "#search_by_groups"
        toolbar_all     : "[data-toolbar] button"
        toolbar_create  : "#create-group-in-organization"
        toolbar_delete  : "#delete-group-in-organization"
        toolbar_edit    : ".toolbar [data-action='edit_group']"
        toolbar_policy  : ".toolbar [data-action='create_policy']"


      tmRoot: 'ED53F9BFF5BC5E3CE0433D003C0A45D300000000'

      config:
        locale          : App.t('organization', { returnObjectTrees: true })
        draggable       : true
        data_key_path   : "ID_PATH"
        dataKeyTitle    : "grouppath"
        dataKeyField    : "GROUP_ID"
        dataLoadField   : "ID_PATH"
        dataChildsField : "childsCount"
        dataParentField : "parents"
        dataTextField   : "DISPLAY_NAME"
        dataIconField   : (group_data) ->
          if group_data.GROUP_TYPE is "adRoot"
            "server"
          else if (
            group_data.GROUP_TYPE is "adGroup"  and
            group_data.SOURCE is "dd"
          )
            group_data.SOURCE
          else
            group_data.GROUP_TYPE
        icons:
          "ad"          : "icon _sizeSmall _folderAd"
          "adGroup"     : "icon _sizeSmall _folderAd"
          "adDomain"    : "icon _sizeSmall _server"
          "adOU"        : "icon _sizeSmall _orgUnit"
          "adContainer" : "icon _sizeSmall _folder"
          "dd"          : "icon _sizeSmall _folderDd"
          "server"      : "icon _sizeSmall _server"
          "tmGroup"     : "icon _sizeSmall _folderTm"
          "tmRoot"      : "icon _sizeSmall _folderTm"

        set_drag_action : (node_data) ->
          if node_data.SOURCE in ["ad", "dd"]
            "copy"
          else
            "move"

      initialize: (options) ->
        @listenTo Organization, "select:group:by:path", _select_group_by_path

        super(
          _.extend(
            {}
            @config
            options
          )
        )

        if options.region
          options.region.show @
        else
          App.Layouts.Application.sidebar.show @


      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onShow: ->
        _setup_search_by_groups @

      onTreeviewBeforeSelect: (flag, node) ->
        Organization.reqres.request "person:workstation:may:lose:changes",
          accept : =>
            @triggerMethod "treeview:select", node
            node.tree.activateKey node.key

      onTreeviewPostinit : ->
        _render_ldap_sync @collection, @getRootNodes()

      onTreeviewSelect: (node) ->
        Organization.reqres.setHandler "drill:down:data", ->
          null

        model = @collection.get node.key
        model.detailed_fetch()
        _toolbar_setup_visibility @, model, node

        if Organization.reqres.request "is:content:entity:view"
          Organization.trigger "manage:visibility:by:group:source",
            model.get "SOURCE"

          Organization.trigger "fetch:group:items", node.key
          Organization.trigger "reset:search:input"
          Organization.trigger "set:persons:workstations:count",
            persons    : @collection.get(node.key).get "personsCount"
            workstations : @collection.get(node.key).get "workstationsCount"

          if model.get('SOURCE') in ['ad', 'dd']  or  App.Configuration.isLocked()
            Organization.trigger "disable:add:person:workstation:item"
          else
            Organization.trigger "enable:add:person:workstation:item"

          for action in ["edit", "delete", "leave:group", "set:status", "create:policy"]
            Organization.trigger "disable:#{ action }:person:workstation:item"

          Organization.trigger "toggle:status_filter"

      dragHandler: (node) ->
        if node.data.GROUP_ID is "adRoot" or node.data.GROUP_TYPE is "tmRoot"
          return false
        else
          return true

      dragDropHandler: (node, sourceNode, hitMode, ui, draggable) ->
        group_model_destination = @collection.get node.key
        group_model_current = @collection.active_model

        if ui?.helper.hasClass "js-persons-workstations-to-group"
          App.Controllers.Organization.contentView.currentView.transfer_to(
            group_model_current
            group_model_destination
            ui.helper.children()
          )

        # Drag внутри дерева
        if sourceNode?
          group_model_source = @collection.get(sourceNode.key)

          App.Helpers.confirm
            title: App.t 'menu.organization'
            data: App.t 'organization.group_to_group',
              action:
                if group_model_source.get("SOURCE") in ["ad", "dd"]
                  App.t 'global.copy'
                else if group_model_source.get("SOURCE") is "tm"
                  App.t 'global.move'
              source_group : sourceNode.title
              dest_group   : node.title

            accept: ->
              group_model_source.transfer_to group_model_destination

      dragEnterHandler: (node, sourceNode, ui) ->
        if App.Configuration.isLocked()
          return false

        # Если задан `sourceNode`, то drug'n'drop работает внутри дерева
        if sourceNode?
          unless helpers.can({action: 'edit', type: 'group'})
            return false

          sourceModel = @collection.get(sourceNode.key)
          destModel = @collection.get(node.key)

          # Если группа имеет тип AD или это корневая группа TM - то запрещаем drop
          if destModel.get("SOURCE") in ["ad", "dd"] or sourceModel.id is "tmRoot"
            return false

          # если уровень вложенности больше 20
          if node.getLevel() > 20
            return false

          # Если тащим в ту же группу
          if destModel.get("GROUP_ID") is sourceModel.get("GROUP_ID")
            return false

          _childs = node.getChildren()

          # Если тащим в ту же родительскую группу - запрещаем drag
          if _childs
            if $.grep(_childs, (e) ->
              return e.key is sourceNode.key
            ).length
              return false

          # если тащим родителя в предка
          if node.isDescendantOf(sourceNode)
            return false

        # Если задан `ui`, то в дерево перетаскивается сторонний элемент
        else if ui?
          entity_type = Organization.reqres.request("get:content:entity:type")[0]

          unless helpers.can({action: 'edit', type: entity_type})
            return false

          dropped = ui.helper

          # Если перетаскиваются персоны/рабочие
          if dropped.hasClass("js-persons-workstations-to-group")
            # Нельзя перетаскивать в "AD", "tmRoot" и активную группу
            if (
              node.key is "tmRoot" or
              @collection.get(node.key).get("SOURCE") in ["ad", "dd"] or
              node.key is @collection.active_model.id
            )
              return false


        return ["before", "after", "over"]

      delete_node: (e) ->
        e?.preventDefault()
        unless helpers.can({action: 'delete', type: 'group'})
          return

        App.Helpers.confirm
          title  : App.t 'menu.organization'
          data   : "#{ App.t 'organization.deleteGroup' }?"
          accept: =>
            active_node = @getSelected()
            parent_group_id = active_node.parent.key

            if (
              @collection.active_model.get("SOURCE") in ["ad", "dd"]  and

              @collection
              .get parent_group_id
              .get("SOURCE") is "tm"
            )
              @collection.active_model.save
                parents : _.filter @collection.active_model.get("parents"), (parent_data) ->
                  parent_data.GROUP_ID isnt parent_group_id
              ,
                wait  : true
                silent  : true
                success : =>
                  @delete active_node
            else
              @collection.active_model.destroy()

      create_policy: (e) ->
        e?.preventDefault()
        if helpers.islock({type: 'policy_person', action: 'edit'}) then return

        data = @getSelected()
        App.Policy?.createPolicy = [
          ID    : data.data.GROUP_ID
          NAME  : data.title
          TYPE  : 'group'
          content : @collection.get(data.data.GROUP_ID).toJSON()
        ]

        App.Routes.Application.navigate "/policy", trigger: true

      edit_node: (e) ->
        e?.preventDefault()

        async.series
          fetch_detailed : (done) =>
            if @collection.active_model.get "parents"
              done()
            else
              @model.detailed_fetch()
              .success -> done()
        , =>
          App.modal.show new GroupsView
            collection          : @collection
            confirm_disabled    :
              if helpers.can({action: 'edit', type: 'group'})
                false
              else
                true
            mode                : "edit"
            parentGroupId       : @getSelected().key
            title               : App.t 'organization.editGroup'

      add_node: (e) ->
        e?.preventDefault()

        unless helpers.can({action: 'edit', type: 'group'})
          return

        App.modal.show (
          new GroupsView
            collection      : @collection
            mode            : "add"
            parentGroupId   : @getSelected().key
            title           : App.t 'organization.createGroup'
        )
