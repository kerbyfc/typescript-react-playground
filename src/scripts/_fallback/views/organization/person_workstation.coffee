"use strict"

async = require "async"
helpers = require "common/helpers.coffee"

require "layouts/organization/person_workstation_add_edit.coffee"
require "views/shared/dialogs/select_elements.coffee"
require "models/organization/persons.coffee"
require "backbone.syphon"
require "layouts/dialogs/confirm.coffee"

StatusesCollection =
  require "models/lists/statuses.coffee"
  .Collection

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

    # ## Класс визуализирует персону/рабочую станцию в виде миниатюры
    class App.Views.Organization.PersonWorkstation extends Marionette.ItemView

      # *************
      #  PRIVATE
      # *************
      _prefetch = ->
        @model.collection.prefetch_groups @model.id

      _remove_if_not_enough_groups = (model) ->
        new Promise (removed, next) ->
          if (
            model.get "groups"
            .length is 0
          )
            model.destroy
              error   : next
              success : removed
              wait    : true
          else
            next()

      _render_edited_now = ->
        @model.fetch
          data :
            with :
              groups : ["NAME_PATH", "ID_PATH"]
          success: =>
            if @model.has 'PERSON_ID'
              type = 'persons'
            else if @model.has 'WORKSTATION_ID'
              type = 'workstations'

            # `@isEditedNow` представляет из себя экземпляр класса формы редактирования персоны/рабочей станции
            @isEditedNow = new App.Layouts.Organization.PersonWorkstationItemAddEdit

              title: App.t "organization.edit_#{type}_dialog_title"

              model: @model

            Organization.trigger "enable:set:status:person:workstation:item"

            App.modal.show @isEditedNow

            @isEditedNow.deserializeModel()

            @$el.addClass "selected"

            # Ожидание события сохранения результатов редактирования персоны/рабочей станции
            @listenTo @isEditedNow, "save:person:workstation:item", _save_item

            # Закончить редактирование персоны/рабочей станции
            @listenTo @isEditedNow, "cancel:edit:person:workstation:item", =>
              @$el.removeClass "selected"
              @isEditedNow.destroy()
              @stopListening @isEditedNow
              @isEditedNow = null

      _save_item = (options) ->
        unless helpers.can({action: 'edit', type: Organization.reqres.request("get:content:entity:type")[0]})
          return

        _remove_if_not_enough_groups @model
        .then(
          _.noop
          =>
            new_data = Backbone.Syphon.serialize options.view

            @model.save(
              _.extend(
                new_data
                DISPLAY_NAME:
                  if new_data.SN  and  new_data.GIVENNAME
                    "#{new_data.SN} #{new_data.GIVENNAME}"
                  else
                    new_data.DISPLAY_NAME
              )

              wait: true
              error : (model, xhr) ->
                if(
                  _.isArray( xhr.responseJSON?.SN )  and
                  "not_unique_field" in xhr.responseJSON.SN  or

                  _.isArray( xhr.responseJSON?.GIVENNAME )  and
                  "not_unique_field" in xhr.responseJSON.GIVENNAME
                )
                  group_name = App.Controllers.Organization.groupsCollection.active_model.get("DISPLAY_NAME")

                  App.Notifier.showError
                    text : App.t 'organization.person_workstation_exist_in_group',
                      type  : App.t("organization.#{ model.type }")
                      name  : "#{ model.get("SN") } #{ model.get("GIVENNAME") }"
                      group :
                        if group_name is "tmRoot"
                          App.t "organization.tmRoot"
                        else
                          _.escape group_name

              success : =>
                group_id = App.Controllers.Organization.groupsView.getSelected().data.GROUP_ID

                @isEditedNow.trigger "cancel:edit:person:workstation:item"

                if (
                  @model.get('groups').find (group) ->
                    group
                    .get "ID_PATH"
                    .match group_id
                )
                  # Если сущность осталась в группе после изменения
                  @render()
                else
                  # если сущность покинула группу после изменения
                  App.Controllers.Organization.groupsCollection.active_model
                  .trigger "reduce:persons:workstations:count", @model.collection.type
                  @destroy()
            )
        )

      _select = (e) ->
        if (
          Organization.reqres.request("is:added:now")  or
          Organization.reqres.request("is:edited:now")
        )
          return

        if (
          navigator.platform is "MacIntel"  and  e.metaKey is false  or
          navigator.platform isnt "MacIntel"  and  e.ctrlKey is false
        )
          @trigger "unselect:all"
        @$el.toggleClass("ui-selected")
        @trigger "selected"

      # TODO: Refactor this module to move data-loading logic to controllers and model logic to views
      _try_edit = (event) ->
        if (event.timeStamp - @mouseDownTimeStamp) < 400
          @model.fetch
            success: =>
              @edit()

        @mouseDownTimeStamp = event.timeStamp


      # *************
      #  PUBLIC
      # *************
      # Метод вызывается из `App.Views.Organization.PersonWorkstations` при событии "edit:person:workstation:item"
      edit: ->
        if @isEditedNow? then return

        passed = =>
          Organization.trigger "cancel:add:edit:person:workstation:item"

          if @model.get("groups").length
            _render_edited_now.call @
          else
            @listenToOnce @model, "sync", _render_edited_now

        if (
          Organization.reqres.request "person:workstation:may:lose:changes",
            callback : passed
        ) isnt false
          passed()


      # **************
      #  BACKBONE
      # **************
      attributes: ->
        "data-model-id": @model.id

      className: "employeeItem"

      events:
        "click"       : _select
        "mousedown"   : _try_edit
        "mouseenter"  : _prefetch

      tagName: "li"


      # ****************
      #  MARIONETTE
      # ****************
      # Сериализация вложенных коллекций (контакты, группы ...) для удобства использования в шаблоне
      serializeData: ->
        data = @model.toJSON()

        for own key, value of data when value instanceof Backbone.Collection
          data[key] = value.toJSON()

        data


      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onBeforeDestroy : ->
        @isEditedNow?.trigger "cancel:edit:person:workstation:item"


    # ## Коллекция миниатюр персон/рабочих станций
    class App.Views.Organization.PersonWorkstations extends Marionette.CompositeView

      # *************
      #  PRIVATE
      # *************
      _add_person_workstation_item = (form_data) ->
        @collection.create(
          _.extend form_data,
            "PARENT_GROUP_ID" :
              App.Controllers.Organization.groupsCollection.active_model.id

          success: (model) ->
            Organization.trigger "increase:persons:workstations:count", model.collection.type
            Organization.trigger "research:entity"

          error : (model, xhr) ->
            if(
              _.isArray( xhr.responseJSON?.SN )  and
              "not_unique_field" in xhr.responseJSON.SN  or

              _.isArray( xhr.responseJSON?.GIVENNAME )  and
              "not_unique_field" in xhr.responseJSON.GIVENNAME  or

              _.isArray( xhr.responseJSON?.DISPLAY_NAME )  and
              "not_unique_field" in xhr.responseJSON.DISPLAY_NAME
            )
              App.Notifier.showError
                text : App.t 'organization.person_workstation_exist_in_group',
                  type  : App.t("organization.#{ model.type }")
                  name  :
                    if model.type is "person"
                      "#{ model.get("SN") } #{ model.get("GIVENNAME") }"
                    else if model.type is "workstation"
                      "#{ model.get "DISPLAY_NAME" }"
                  group : do ->
                    active_group_model = App.Controllers.Organization.groupsCollection.active_model

                    if active_group_model.get("DISPLAY_NAME") is "tmRoot"
                      App.t "organization.tmRoot"
                    else
                      _.escape active_group_model.get("DISPLAY_NAME")

          wait: true
        )


      # *************
      #  PUBLIC
      # *************
      lazy_load : ->
        if @collection.is_all_loaded()
          return

        if (@$childViewContainer.height() + @$childViewContainer.offset().top) < 1000
          if Organization.reqres.request("drill:down:data")
            Organization.trigger "lazy:load:with:drill:down"
          else if  Organization.reqres.request("get:search:query") and Organization.reqres.request("get:search:query") isnt ""
            Organization.trigger "lazy:load:with:search"
          else
            @collection.loadMoreItems()


      itemView: App.Views.Organization.PersonWorkstation

      className: "tab-pane active"

      collectionEvents:
        "sort": ->
          if @$child-view-container
            @_make_draggable()

        "remove": ->
          Organization.trigger "unselected"

        "request": (collection, xhr, options) ->
          if collection instanceof Backbone.Collection
            unless options.not_cancel_editing
              Organization.trigger "cancel:add:edit:person:workstation:item"
            xhr.always =>
              if @$child-view-container
                @_make_draggable()

      initialize: ->
        # Закрыть все окна создания/редактирования персон/рабочих станций
        @listenTo Organization, "cancel:add:edit:person:workstation:item", ->
          @isAddedNow?.trigger "cancel:add:person:workstation:item"
          @children.each (view) -> view.isEditedNow?.trigger "cancel:edit:person:workstation:item"

        @listenTo Organization, "set:status:person:workstation:item", @onSetStatusPersonWorkstationItem

      attachHtml: (collection_view, item_view, index) ->
        if collection_view.emptyView is item_view.constructor
          return super

        jq_elems = @$childViewContainer?.children(":not(.unit_list--edit)")

        if jq_elems?  and  index < jq_elems.length
          jq_elems.eq(index).before(item_view.el)
        else
          super

      onChildviewUnselectAll: ->
        @children.each (view) -> view.$el.removeClass "ui-selected"

      onChildviewSelected: (view) -> @$childViewContainer.trigger "selectableselected", view.$el

      onDomRefresh: ->
        @$childViewContainer.selectable
          cancel: ".unit_list--edit"
          # selected: => Смотреть @$childViewContainer.on "selectableselected"
          unselected: ->
            Organization.trigger "unselected"

          selecting: (e, ui) =>
            jq_el = $(ui.selecting)
            jq_el.addClass("selected")  if jq_el.hasClass("employee")
            if (model_id = ui.selecting.dataset.modelId)?
              @collection.prefetch_groups(model_id)

          unselecting: (e, ui) ->
            jq_el = $(ui.unselecting)
            jq_el.removeClass("selected")  if jq_el.hasClass("employee")

        @$childViewContainer.on "selectableselected", (e, el) =>
          $el = $(el)
          unless $el.hasClass "ui-selected"
            $el.removeClass "selected"

          selectable_length = @$childViewContainer.children(".ui-selected").length

          Organization.trigger "selected", selectable_length

        @_make_draggable()

      onSetStatusPersonWorkstationItem: (from_edited) ->
        unless @isRendered
          return

        if helpers.islock({action: 'set_status', type: @name.replace(/s$/, '')})
          return

        if @isAddedNow?
          views = [@is-added-now]
        else
          $els = @$childViewContainer.children(".ui-selected")
          unless $els.length then return

          views = for el in $els
            @children.find (view) -> view.el is el

        statuses_ = _.reduce views, (accum, view) ->
          accum.concat(
            _.pluck view.model.get('status').toJSON(), "IDENTITY_STATUS_ID"
          )
        ,
          []

        collection = new StatusesCollection

        collection.filter = filter:
          EDITABLE: 1

        App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
          title: App.t 'organization.set_status'
          template: "organization/person_workstation_set_status"
          selected: statuses_
          collection: collection
          table_config:
            default:
              sortCol: "DISPLAY_NAME"
            columns: [
              {
                id      : "COLOR"
                name    : ""
                field   : "COLOR"
                width   : 40
                resizable : false
                sortable  : true
                cssClass  : "center"
                formatter : (row, cell, value, columnDef, dataContext) ->
                  "<div style='height:16px;width:16px;background-color:#{dataContext.get('COLOR')}'></div>"
              }
              {
                id      : "DISPLAY_NAME"
                name    : App.t 'lists.statuses.display_name'
                field   : "DISPLAY_NAME"
                resizable : true
                sortable  : true
                minWidth  : 150
              }
              {
                id      : "NOTE"
                name    : App.t 'lists.statuses.note'
                resizable : true
                sortable  : true
                minWidth  : 150
                field   : "NOTE"
              }
            ]
          callback: (added_statuses, removed_statuses, data) ->
            _.each views, (view) ->
              if added_statuses.length
                if data.NOTE
                  _.each added_statuses, (status_model) ->
                    status_model.set "ADD_NOTE", data.NOTE

                view.model.get "status"
                .add added_statuses
              if removed_statuses.length
                view.model.get "status"
                .remove removed_statuses

              if not from_edited
                view.model.save null,
                  success : ->  view.render()

      onLeaveGroupPersonWorkstationItem: ->
        # Прверяем права
        if helpers.islock({action: 'edit', type: @name.replace(/s$/, '')})
          return

        # Проверяем есть ли выделенные сущности
        $els = @$childViewContainer.children(".ui-selected")
        unless $els.length then return

        current_group_model = App.Controllers.Organization.groupsCollection.active_model
        type = @collection.type

        views = for el in $els
          @children.find (view) -> view.el is el

        has_one_group = []

        for view in views
          groups_length = view.model.get("groups").length
          # Где-то группы не успели профетчиться
          if groups_length is 0
            return
          else if groups_length is 1
            has_one_group.push _.escape "\"#{view.model.get("DISPLAY_NAME")}\""

        officer_say_yes = $.Deferred()
        officer_say_yes.done =>
          _.each views, (view) =>
            if has_one_group.length > 0
              view.model.destroy()
            else
              groups = view.model.get "groups"
              groups.remove current_group_model

              view.model.save null,
                wait: true
                success: =>
                  view.isEditedNow?.trigger "cancel:edit:person:workstation:item"
                  current_group_model.trigger(
                    "reduce:persons:workstations:count"
                    view.model.collection.type
                  )
                  @collection.remove view.model


        if has_one_group.length is 0
          App.Helpers.confirm
            title: App.t 'organization.leave_current_group'
            data: do ->
              type = App.t('organization', { returnObjectTrees: true })[type].toLowerCase()
              App.t 'organization.leave_group_question',
                items : """
                  #{type}:
                  #{has_one_group.join(", ")}
                """
            accept: -> officer_say_yes.resolve()
        else
          App.Helpers.confirm
            title: App.t 'organization.leave_current_group'
            data: do ->
              type = App.t('organization', { returnObjectTrees: true })[type].toLowerCase()
              App.t 'organization.has_last_group',
                items : """
                  #{type}:
                  #{has_one_group.join(", ")}
                """
                type : type
            accept: -> officer_say_yes.resolve()

      onCreatePersonPolicy: ->
        jqElems = @$childViewContainer.children ".ui-selected"
        return unless jqElems.length

        App.Policy.createPolicy = []
        jqElems.each (i, item) =>
          model = @collection.get $(item).data('model-id')

          App.Policy.createPolicy.push
            ID    : model.id
            NAME  : model.getName()
            TYPE  : @name.slice(0, @name.length - 1)
            content : model.toJSON()

        App.Routes.Application.navigate "/policy", trigger: true

      getSelected: ->
        jqElems = @$childViewContainer.children(".ui-selected")
        unless jqElems.length
          return []

        _.map jqElems, (elem) =>
          @collection.get $(elem).data('model-id')


      # #### При клике на удалить персону/рабочую станцию
      onDeletePersonWorkstationItem: ->
        if helpers.islock({action: 'delete', type: @name.replace(/s$/, '')})
          return

        jqElems = @$childViewContainer.children(".ui-selected")
        unless jqElems.length
          return

        views = []
        i = jqElems.length
        while i--
          views.push @children.find (view) -> view.el is jqElems[i]

        App.Helpers.confirm
          title: do =>
            if @collection.model::idAttribute is "PERSON_ID"
              App.t 'organization.delete_person_modal',

                count :
                  if jqElems.length is 1
                    ""
                  else
                    jqElems.length

                type :
                  App.Helpers.pluralize(
                    jqElems.length
                    nom: App.t 'organization.person_nom'
                    gen: App.t 'organization.person_gen'
                    plu: App.t 'organization.person_plu'
                  )
            else if @collection.model::idAttribute is "WORKSTATION_ID"
              App.t 'organization.delete_workstation_modal',

                count :
                  if jqElems.length is 1
                    ""
                  else
                    jqElems.length

                type :
                  App.Helpers.pluralize(
                    jqElems.length
                    nom: App.t 'organization.workstation_nom'
                    gen: App.t 'organization.workstation_gen'
                    plu: App.t 'organization.workstation_plu'
                  )

          accept: ->
            i = views.length
            while i--
              if views[i].model.get("SOURCE") in ["ad", "dd"]
                App.Notifier.showError
                  text    : App.t 'organization.ad_not_removed', name : views[i].model.get("DISPLAY_NAME")
                  delay   : 4000
              else
                groups = views[i].model.get("groups")
                j = groups.length
                views[i].isEditedNow?.trigger "cancel:edit:person:workstation:item"
                views[i].model.destroy()

      # #### При добавлении персоны/рабочей станции
      onAddPersonWorkstationItem: ->
        if helpers.islock({action: 'edit', type: @name.replace(/s$/, '')})
          return

        if @isAddedNow? then return

        passed = =>
          Organization.trigger "cancel:add:edit:person:workstation:item"
          Organization.trigger "enable:set:status:person:workstation:item"

          @isAddedNow = new App.Layouts.Organization.PersonWorkstationItemAddEdit

            title: App.t "organization.add_#{@name}_dialog_title"

            model: (
              new_model = new @collection.model()
              new_model.collection = @collection
              new_model
            )

          @isAddedNow.model.addExistingGroup(
            App.Controllers.Organization.groupsCollection.get(
              App.Controllers.Organization.groupsView.getSelected().data.GROUP_ID
            )
          )

          App.modal.show @isAddedNow

          @listenTo @isAddedNow, "save:person:workstation:item", (options) =>
            options.model.set Backbone.Syphon.serialize(
              options.view,
              exclude: ["unit_edit--mode"]
            )
            isValid = options.model.validate()

            unless isValid?
              _add_person_workstation_item.call @, options.model.toJSON()

          @listenTo @isAddedNow, "cancel:add:person:workstation:item", =>
            Organization.trigger "disable:set:status:person:workstation:item"
            # Очистить вложенные коллекции (контакты, группы и т. д.)
            for own key of @isAddedNow.model.toJSON() when @isAddedNow.model.get(key) instanceof Backbone.Collection
              @isAddedNow.model.get(key).reset()

            @isAddedNow.destroy()
            @isAddedNow = null

        if (
          Organization.reqres.request "person:workstation:may:lose:changes",
            callback : passed
        ) isnt false
          passed()

      # #### Найти первую выделенную персону/рабочую станцию и открыть окно редактирования оной
      onEditPersonWorkstationItem: ->
        el = @$childViewContainer.children(".ui-selected")[0]
        view = @children.find (view) -> view.el is el

        view.model.fetch
          success: ->
            view.edit() if view?

      _make_draggable: ->
        # Если песочница залочена, отключаем Drag & drop
        if App.Configuration.isLocked() then return

        @$childViewContainer.children().draggable
          connectToFancytree : true
          cursorAt:
            left : -20
            top  : -20
          # <a target=_blank href="http://jsbin.com/awagi">Костыль для мультидрага</a>
          helper: (event) =>
            el = $ event.target
            selected = @$childViewContainer.children ".ui-selected"
            unless selected.length
              if el.hasClass "employeeItem"
                selected = el
              else
                selected = el.closest ".employeeItem"

            entity = Organization.reqres.request("get:content:entity:type")[0]

            helper_text = App.t "organization.drag_helper",
              count: selected.length
              type:
                App.Helpers.pluralize(
                  selected.length
                  nom: App.t "organization.#{entity}_nom"
                  gen: App.t "organization.#{entity}_gen"
                  plu: App.t "organization.#{entity}_plu"
                )

            helper = $("<div>#{helper_text}</div>")
              .attr('data-ids', _.map selected, (el) -> el.dataset.modelId)

            $('<div>')
              .addClass("js-persons-workstations-to-group")
              .append(helper)
              .appendTo("body")

      transfer_to: (group_model_current, group_model_destination, elems) ->
        ids = elems.attr('data-ids').split(',')

        App.Helpers.confirm
          confirm: do ->
            if group_model_current.get("SOURCE") in ["ad", "dd"]
              [App.t 'global.add']
            else
              [
                App.t 'global.add'
                App.t 'organization.add_excluding_current'
              ]
          title: App.t 'organization.move_to_group',
            count: ids.length
            entity:
              App.Helpers.pluralize ids.length,
                (
                  entity = Organization.reqres.request("get:content:entity:type")[0]

                  if entity is "workstation"
                    nom: App.t 'organization.workstation_nom'
                    gen: App.t 'organization.workstation_gen'
                    plu: App.t 'organization.workstation_plu'
                  else if entity is "person"
                    nom: App.t 'organization.person_nom'
                    gen: App.t 'organization.person_gen'
                    plu: App.t 'organization.person_plu'
                )
            group:
              if group_model_destination.get("DISPLAY_NAME") is "tmRoot"
                App.t "organization.tmRoot"
              else
                _.escape group_model_destination.get("DISPLAY_NAME")

          accept: (action_code) =>
            action = "copy"  if action_code is 0
            action = "move"  if action_code is 1

            async.each ids, (id, done) =>
              model = @collection.get id

              # Params for notifier message
              notifierMessageParams =
                type: App.t("organization.#{model.type}")
                name: model.get("DISPLAY_NAME")
                group:
                  if group_model_destination.get("DISPLAY_NAME") is "tmRoot"
                    App.t "organization.tmRoot"
                  else
                    _.escape group_model_destination.get("DISPLAY_NAME")

              # Check if model already in group
              if model.get('groups').get(group_model_destination.id)
                App.Notifier.showError(text: App.t 'organization.person_workstation_exist_in_group', notifierMessageParams)

                return

              model.save
                contacts: model.get("contacts").toJSON()
                groups:
                  _ model.get("groups").toJSON()
                  .tap (group_data) ->
                    if action is "move"
                      _.remove group_data, GROUP_ID : group_model_current.id
                    group_data.push
                      GROUP_ID : group_model_destination.id
                      SOURCE   : group_model_destination.get "SOURCE"
                  .value()
              ,
                wait: true

                success: =>
                  if action is "move"
                    App.Controllers.Organization.contentView.currentView.children.findByModel(model)
                      .isEditedNow?.trigger("cancel:edit:person:workstation:item")

                    @collection.remove(id)

                    group_model_current.set "#{@collection.type}Count",
                      group_model_current.get(
                        "#{@collection.type}Count"
                      ) - 1

                  App.Notifier.showSuccess(text: App.t 'organization.person_workstation_added_to_group', notifierMessageParams)

                error: (model, response)->
                  switch response.responseText
                    when "unique"
                      App.Notifier.showError(text: App.t 'organization.person_workstation_exist_in_group', notifierMessageParams)

              .always -> done()
