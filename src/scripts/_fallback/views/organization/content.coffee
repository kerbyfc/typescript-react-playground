"use strict"

helpers = require "common/helpers.coffee"
co = require "co"
StatusesCollection =
  require "models/lists/statuses.coffee"
  .Collection

require "layouts/dialogs/confirm.coffee"
require "views/controls/tab_view.coffee"
require "views/organization/persons.coffee"
require "views/organization/workstations.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

    class App.Views.Organization.TabView extends App.Views.Controls.TabChildView

      template: 'organization/tab_item'

      tagName: 'button'

      className: 'button _grey'

      attributes: ->
        {
          type: 'button'
          "data-tab-id": @model.get 'name'
        }

    class App.Views.Organization.Content extends App.Views.Controls.TabView

      # *************
      #  PRIVATE
      # *************
      _get_allowed_tabs = ->
        unless helpers.can({type: 'person'})
          for obj, key in @config.tabs
            if obj.name is "persons"
              @config.tabs[key] = null
              @config.tabs = _.compact @config.tabs
              break

        unless helpers.can({type: 'workstation'})
          for obj, key in @config.tabs
            if obj.name is "workstations"
              @config.tabs[key] = null
              @config.tabs = _.compact @config.tabs
              break

      _change_initial_tab_to_workstations = ->
        unless (
          _.find @config.tabs,
            (tab) ->
              tab.name is "persons"
        )
          @config.initialTab = "workstations"

      _get_content_entity_type = ->
        [
          @currentView?.collection.model::type
          @currentView?.collection.type
        ]

      _get_search_filter = ->
        val = @ui.state_filter.select2('val')
        if val
          {DISABLED: @ui.state_filter.select2('val')}
        else
          {}

      _get_status_filter = ->
        @ui.status_filter.val() or []

      _get_search_query = ->
        @ui.search.val()

      _set_search_query = (value) ->
        if value
          @ui.search.val value

        # По умолчанию восстановить предсохранённый поисковый запрос
        else
          @ui.search.val _preserved_search_queries[@cid]

      _is_content_entity_view = ->
        !!@currentView

      _lazy_load_with_search = ->
        @_search_person_workstation _get_search_query.call(@),
          null
          true

      _lazy_load_with_drill_down = ->
        @_search_person_workstation null,
          Organization.reqres.request "drill:down:data"
          true

      _manage_visibility_by_group_source = (group_source) ->
        if group_source is "ad"
          @ui.state_filter.closest('.controlPanel__item').show()
        else
          @ui.state_filter.closest('.controlPanel__item').hide()

        if group_source is "dd"
          @children.findByIndex 0
          .$el.click()

          @children.findByIndex 1
          ?.$el.hide()
        else
          @children.findByIndex 1
          ?.$el.show()

      _research_entity = ->
        @_search_person_workstation _get_search_query.call(@)

      _retrieve_edited = ->
        @current-view?.children.find (view) ->
          view.isEditedNow

      _retrieve_added = ->
        @currentView?.isAddedNow

      _preserved_search_queries = {}

      _preserve_search_query = (value, cid) ->
        _preserved_search_queries[cid] = value

      _search_person_workstation_passed = (query) ->
        Organization.reqres.setHandler "drill:down:data", ->
          null

        @_search_person_workstation query

      _person_workstation_may_lose_changes = (modal_options) ->
        if (
          Organization.reqres.request("is:added:now")  or
          ( edited = !!Organization.reqres.request("is:edited:now") )
        )
          modal = new App.Layouts.confirmDialog _.extend(
            title : App.t(
              "organization.person_workstation_may_lose_changes"
              action :
                if edited
                  App.t "global.edited_process"
                else
                  App.t "global.created_process"
              entity : App.t "organization.#{ Organization.reqres.request("get:content:entity:type")[0] }"
            )
            modal_options
          )

          App.modal.show modal

          false

      _reset_search_input = ->
        @ui.search.val ""

      _setup_lazy_load = (self) ->
        entity_region = self.regionManager.get "tabContent"

        entity_region.$el.on "scroll", _.throttle ->
          entity_region.currentView.lazy_load()
        ,
          650

      _setup_state_filter = (self) ->
        self.ui.state_filter.select2
          minimumResultsForSearch: 100
        .on "change", ->
          self.set_filter_search()

      _setup_status_filter = (self) -> co ->
        yield self.status_collection.fetch()

        statuses = _.map self.status_collection.toJSON(), (status_data) ->
          {label: status_data.DISPLAY_NAME, value: status_data.IDENTITY_STATUS_ID}

        self.ui.status_filter.multiselect
          buttonClass     : 'btn btn-link'
          buttonTitle     : -> ""
          enableHTML      : true
          buttonText: (options, select) ->
            if options.length is 0
              return App.t 'organization.non_statuses_selected'
            else if options.length > 2
              App.t 'organization.selected_statuses',
                statuses: App.t 'lists.statuses.status', {count: options.length}
            else
              selected = ''
              options.each ->
                label = if ($(@).attr('label') isnt undefined) then $(@).attr('label') else $(@).text()

                selected += label + ', '

              return selected.substr(0, selected.length - 2) + ' <b class="caret"></b>'
          optionLabel: (element) ->
            label = $.fn.multiselect.Constructor.prototype.defaults.optionLabel(element)

            if @multiple
              label = '<span></span>' + label

            label
          templates:
            li: ->
              $li = $('<li><a tabindex="0"><label></label></a></li>')

              if @options.multiple
                $('label', $li).addClass('form__checkbox')

              if @options.enableCollapsibleOptGroups
                $('label', $li).addClass('subgroup')

              $li.prop('outerHTML')

        .on "change", ->
          self.currentView.collection.fetchGroupItems()

        self.ui.status_filter.multiselect('dataprovider', statuses)

      # ***************
      #  PROTECTED
      # ***************
      _search_person_workstation:
        _.throttle(
          (
            query
            filter
            lazy
          ) ->
            @currentView.collection.search(
              $.trim(query)
              filter
              lazy
            )
          777
        )

      search_person_workstation_handler : (e) ->
        if Organization.reqres.request(
          "person:workstation:may:lose:changes"

          callback  : _.bind _search_person_workstation_passed, @, e.target.value
          on_cancel : _.bind _set_search_query, @
        ) isnt false
          _search_person_workstation_passed.call @, e.target.value

      set_filter_search: (e) ->
        e?.preventDefault()

        @_search_person_workstation(
          _get_search_query.call @
        )


      # ****************
      #  MARIONETTE
      # ****************
      className: 'content employee'

      regions:
        tabContent: "#tm-organization-tab-content"

      childViewContainer: "#tm-organization-tabs"

      childView: App.Views.Organization.TabView

      getTemplate: ->
        if @config.tabs.length
          "organization/content"
        else
          "organization/content_blocker"

      ui:
        search                                          : "input.contentHeader__filter"
        state_filter                                    : "#state_filter"
        status_filter                                   : "#status_filter"
        add_person_workstation_item_button              : "#add-person-workstation-item"
        edit_person_workstation_item_button             : "#edit_try_edit-person-workstation-item"
        delete_person_workstation_item_button           : "#delete-person-workstation-item"
        leave_group_person_workstation_item_button      : "#leave-group-person-workstation-item"
        set_status_item_button                          : "#person-workstation-set-status-item"
        create_policy                                   : "#person-create-policy"

      triggers:
        "click #add-person-workstation-item"            : "add:person:workstation:item"
        "click #edit_try_edit-person-workstation-item"  : "edit:person:workstation:item"
        "click #delete-person-workstation-item"         : "delete:person:workstation:item"
        "click #leave-group-person-workstation-item"    : "leave:group:person:workstation:item"
        "click #person-workstation-set-status-item"     : "set:status:person:workstation:item"
        "click #person-create-policy"                   : "create:person:policy"


      # **************
      #  BACKBONE
      # **************
      events:
        "input .searchBlock__field"       : "search_person_workstation_handler"
        "keydown .searchBlock__field"     : (e) -> _preserve_search_query e.target.value, @cid


      # ************
      #  PUBLIC
      # ************
      config:
        initialTab: "persons"

        tabs: [
          label: -> App.t 'organization.persons'
          name: "persons"
        ,
          label: -> App.t 'organization.workstations'
          name: "workstations"
        ]

      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onAddPersonWorkstationItem: -> @currentView.triggerMethod "add:person:workstation:item"
      onEditPersonWorkstationItem: -> @currentView.triggerMethod "edit:person:workstation:item"
      onDeletePersonWorkstationItem: -> @currentView.triggerMethod "delete:person:workstation:item"
      onLeaveGroupPersonWorkstationItem: -> @currentView.triggerMethod "leave:group:person:workstation:item"
      onSetStatusPersonWorkstationItem: -> Organization.trigger "set:status:person:workstation:item"
      onCreatePersonPolicy: -> @currentView.triggerMethod "create:person:policy"

      _updateToolbar: (view) ->
        $('.controlPanel__toolbar button').each (index, element) ->
          if $(element).attr('id') in [
            'add-person-workstation-item'
            'edit_try_edit-person-workstation-item'
            'delete-person-workstation-item'
          ]
            locale = App.t("organization", { returnObjectTrees: true })
            action = $(element).attr('id').split('-')[0].split('_')[0]
            $(element).prop('title', locale["#{action}_#{view.name.replace(/s$/, '')}"])

          if $(element).attr('id') is 'person-create-policy'
            if view.name is 'workstations'
              $(element).hide()
            else
              $(element).show()

      onShow: ->
        @on "after:tab_changed", (view) =>
          @_updateToolbar(view)

        super()

        _setup_status_filter @
        _setup_state_filter @
        _setup_lazy_load @

      onBeforeTabClicked : (childView) ->
        Organization.reqres.request "person:workstation:may:lose:changes",
          callback : =>
            @triggerMethod "childview:tab:clicked", childView

      onChildviewTabClicked : (childView) ->
        Organization.reqres.setHandler "drill:down:data", ->
          null

        _.defer =>
          @swapViews.findByCustom childView.model.get @params.id
          .collection.search(
            _get_search_query.call @
            @ui.state_filter.select2('val')
          )
          .success =>
            super childView

            groupId = App.Controllers.Organization.groupsView.getSelected()?.data.GROUP_ID
            if groupId
              model = App.Controllers.Organization.groupsView.collection.get groupId

            if (
              groupId is "tmRoot"  or
              model?.get('SOURCE') is 'ad'  or
              App.Configuration.isLocked()
            )
              Organization.trigger "disable:add:person:workstation:item"
            else
              Organization.trigger "enable:add:person:workstation:item"

        # Останавливаем предыдущие запросы
        $.xhrPool.abortAll()


      # **********
      #  INIT
      # **********
      initialize: (options) ->
        @status_collection = new StatusesCollection
        @status_collection.perPage = 1000

        @listenTo Organization, "unselected", ->
          @ui.edit_person_workstation_item_button.prop("disabled", true)
          @ui.delete_person_workstation_item_button.prop("disabled", true)
          @ui.leave_group_person_workstation_item_button.prop("disabled", true)
          @ui.set_status_item_button.prop("disabled", true)
          @ui.create_policy.prop("disabled", true)

        @listenTo Organization, "selected", (selected) ->
          selected_models = @currentView.getSelected()
          _has_ad_or_dd = _.find selected_models, (elem) -> elem.get('SOURCE') in ['ad', 'dd']

          if selected is 0 or App.Configuration.isLocked()
            @ui.delete_person_workstation_item_button.prop("disabled", true)
            @ui.leave_group_person_workstation_item_button.prop("disabled", true)
            @ui.edit_person_workstation_item_button.prop("disabled", true)
            @ui.set_status_item_button.prop("disabled", true)
            @ui.create_policy.prop("disabled", true)

          else if selected >= 1
            if selected is 1
              @ui.edit_person_workstation_item_button.prop("disabled", false)
              @ui.set_status_item_button.prop("disabled", false)
              @ui.create_policy.prop("disabled", false)

            if selected > 1
              @ui.edit_person_workstation_item_button.prop("disabled", true)
              @ui.set_status_item_button.prop("disabled", false)
              @ui.create_policy.prop("disabled", false)

            unless helpers.can({action: 'edit', type: 'policy_object'})
              @ui.create_policy.prop("disabled", true)

            if (
              @currentView.name is "persons"  and
              not helpers.can({action: 'set_status', type: 'person'})
            )
              @ui.set_status_item_button.prop("disabled", true)

            else if (
              @currentView.name is "workstations"  and
              not helpers.can({action: 'set_status', type: 'workstation'})
            )
              @ui.set_status_item_button.prop("disabled", true)

            if App.Controllers.Organization.groupsCollection.active_model.get("SOURCE") isnt "ad" or
               App.Controllers.Organization.groupsCollection.active_model.get("SOURCE") isnt "dd"
              @ui.delete_person_workstation_item_button.prop("disabled", false)
              @ui.leave_group_person_workstation_item_button.prop("disabled", false)

              if (
                @currentView.name is "persons"  and
                (not helpers.can({action: 'delete', type: 'person'}) or
                 _has_ad_or_dd isnt undefined)
              )
                @ui.delete_person_workstation_item_button.prop("disabled", true)

              else if (
                @currentView.name is "workstations"  and
                not helpers.can({action: 'delete', type: 'workstation'})
              )
                @ui.delete_person_workstation_item_button.prop("disabled", true)

              if (
                @currentView.name is "persons"  and
                not helpers.can({action: 'edit', type: 'person'})
              )
                @ui.leave_group_person_workstation_item_button.prop("disabled", true)

              else if (
                @currentView.name is "workstations"  and
                not helpers.can({action: 'edit', type: 'workstation'})
              )
                @ui.leave_group_person_workstation_item_button.prop("disabled", true)

        @listenTo Organization, "toggle:status_filter", ->
          if App.Controllers.Organization.groupsView.getSelected().data.SOURCE is 'tm'
            @ui.state_filter.closest('.controlPanel__filter').hide()
          else
            @ui.state_filter.closest('.controlPanel__filter').show()

        # Отключить возможность добавления персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "disable:add:person:workstation:item", ->
          if _.isElement @ui.add_person_workstation_item_button[0]
            @ui.add_person_workstation_item_button.prop("disabled", true)

        @listenTo Organization, "disable:edit:person:workstation:item", ->
          if _.isElement @ui.edit_person_workstation_item_button[0]
            @ui.edit_person_workstation_item_button.prop("disabled", true)

        # Отключить возможность удаления персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "disable:delete:person:workstation:item", ->
          if _.isElement @ui.delete_person_workstation_item_button[0]
            @ui.delete_person_workstation_item_button.prop("disabled", true)

        # Отключить возможность покинуть группу персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "disable:leave:group:person:workstation:item", ->
          if _.isElement @ui.leave_group_person_workstation_item_button[0]
            @ui.leave_group_person_workstation_item_button.prop("disabled", true)

        @listenTo Organization, "disable:create:policy:person:workstation:item", ->
          if _.isElement @ui.create_policy[0]
            @ui.create_policy.prop("disabled", true)


        # Отключить возможность выставить статус
        @listenTo Organization, "disable:set:status:person:workstation:item", ->
          @ui.set_status_item_button.prop("disabled", true)  if _.isElement @ui.set_status_item_button[0]

        # Включить возможность добавления персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "enable:add:person:workstation:item", ->
          if (
            @currentView.name is "persons" and
            not helpers.can({action: 'edit', type: 'person'})
          )
            @ui.add_person_workstation_item_button.prop("disabled", true)
            return

          else if (
            @currentView.name is "workstations" and
            not helpers.can({action: 'edit', type: 'workstation'})
          )
            if _.isElement @ui.add_person_workstation_item_button[0]
              @ui.add_person_workstation_item_button.prop("disabled", true)
            return

          if _.isElement @ui.add_person_workstation_item_button[0]
            @ui.add_person_workstation_item_button.prop("disabled", false)

        # Включить возможность добавления персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "enable:delete:person:workstation:item", ->
          if (
            @currentView.name is "persons"  and
            not helpers.can({action: 'delete', type: 'person'})
          )
            @ui.delete_person_workstation_item_button.prop("disabled", true)
            return

          else if (
            @currentView.name is "workstations"  and
            not helpers.can({action: 'delete', type: 'workstation'})
          )
            @ui.delete_person_workstation_item_button.prop("disabled", true)
            return

          if _.isElement @ui.delete_person_workstation_item_button[0]
            @ui.delete_person_workstation_item_button.prop("disabled", false)

        # Включить возможность покинуть группу персоны/рабочей станции в зависимости от группы
        @listenTo Organization, "enable:leave:group:person:workstation:item", ->
          if (
            @currentView.name is "persons"  and
            not helpers.can({action: 'edit', type: 'person'})
          )
            @ui.leave_group_person_workstation_item_button.prop("disabled", true)
            return

          else if (
            @currentView.name is "workstations"  and
            not helpers.can({action: 'edit', type: 'workstation'})
          )
            @ui.leave_group_person_workstation_item_button.prop("disabled", true)
            return

          if _.isElement @ui.leave_group_person_workstation_item_button[0]
            @ui.leave_group_person_workstation_item_button.prop("disabled", false)

        # Включить возможность выставить статус
        @listenTo Organization, "enable:set:status:person:workstation:item", ->
          if (
            Organization.reqres.request("get:content:entity:type")[1] isnt
            @currentView.name
          )
            return

          unless helpers.can({action: 'set_status', type: @currentView.name.replace(/s$/, '')})
            @ui.set_status_item_button.prop("disabled", true)
            return

          @ui.set_status_item_button.prop("disabled", false)  if _.isElement @ui.set_status_item_button[0]

        _.extend @config, options.config
        _get_allowed_tabs.call @
        _change_initial_tab_to_workstations.call @

        super @config

        for tab in @config.tabs
          @addView new App.Views.Organization[App.Helpers.camelCase(tab.name, true)](
            collection : options["#{ tab.name }Collection"]
          ),
          tab.name

        # ##### Вызывается в: <br> <a href="../../controllers/organization.coffee.html#set-count">при выборе группы</a>
        # <br> <a href="person_workstation.coffee.html#set-count-delete">при удалении персон/рабочих станций</a>
        @listenTo Organization, "set:persons:workstations:count", (data) =>
          for own key, value of data
            if value?  and  @$childViewContainer?
              @$childViewContainer
              .find "[data-tab-id=#{key}]"
              .find ".js-count"
              .text "#{value}"

        @listenTo Organization, "manage:visibility:by:group:source", _manage_visibility_by_group_source

        @listenTo Organization, "lazy:load:with:search", _lazy_load_with_search

        @listenTo Organization, "lazy:load:with:drill:down", _lazy_load_with_drill_down

        @listenTo Organization, "research:entity", _research_entity

        @listenTo Organization, "reset:search:input", _reset_search_input

        Organization.reqres.setHandler "person:workstation:may:lose:changes",
          _person_workstation_may_lose_changes

        Organization.reqres.setHandler "get:content:entity:type",
          _get_content_entity_type
          @

        Organization.reqres.setHandler "get:search:filter",
          _get_search_filter
          @

        Organization.reqres.setHandler "get:status:filter",
          _get_status_filter
          @

        Organization.reqres.setHandler "get:search:query",
          _get_search_query
          @

        Organization.reqres.setHandler "is:edited:now",
          _retrieve_edited
          @

        Organization.reqres.setHandler "is:added:now",
          _retrieve_added
          @

        Organization.reqres.setHandler "is:content:entity:view",
          _is_content_entity_view
          @

        App.Layouts.Application.content.show @
