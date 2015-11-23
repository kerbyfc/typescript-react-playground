"use strict"

helpers = require "common/helpers.coffee"
require "backbone.syphon"
require "jquery.fileupload"
require "backbone.stickit"

require "layouts/dialogs/crop.coffee"
require "layouts/dialogs/confirm.coffee"

require "views/organization/contacts.coffee"
require "views/organization/person_workstation_add_edit_groups.coffee"
require "views/organization/workstation_add_edit_persons.coffee"
require "views/organization/person_add_edit_workstations.coffee"
require "views/organization/person_workstation_add_edit_statuses.coffee"

require "behaviors/organization/ad_tm_name.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone) ->

    App.Layouts.Organization ?= {}

    class App.Layouts.Organization.PersonWorkstationItemAddEdit extends App.Layouts.ConfirmDialog

      tagName: "li"

      className: "unit_list--edit"

      children: new Backbone.ChildViewContainer()

      ui:
        "add_ava_to_person" : "#add-ava-to-person"
        "delete_ava_person" : "#delete_ava_person"
        "ava_preview"       : "#ava-preview"
        "tm_manager"        : "#tm_manager"
        "tm_manager_id"     : "#tm_manager_id"

      events:
        "click #delete_ava_person": "_deleteAva"

      triggers:
        "click [data-action=accept]": "save:person:workstation:item"

      regions:
        contacts:     "#unit_tabs--contacts"
        groups:       "#unit_tabs--groups"
        persons:      "#unit_tabs--persons"
        workstations: "#unit_tabs--workstations"
        statuses:     "#unit_tabs--statuses"

      behaviors:
        "ad_tm_name" :
          behaviorClass : App.Behaviors.Organization.ADTMName
        Form:
          behaviorClass: App.Behaviors.Common.Form

      bindings:
        "#add-ava-to-person":
          attributes: [
            name: "style"
            observe: "HAS_TM_THUMBNAILPHOTO"
            onGet: (val) ->
              if val
                "display: none"
              else
                ""
          ]
        "#ava-preview":
          attributes: [
            name: "src"
            observe: "HAS_TM_THUMBNAILPHOTO"
            onGet: (val) ->
              if @ava
                @ava
              else if @model.get('SOURCE') in ['ad', 'dd']  or  val
                """
                  #{App.Config.server}/api/ldapPerson/image?\
                  person_id=#{@model.get 'PERSON_ID'}&\
                  t=#{ Math.round +new Date() / 1000 }
                """
              else
                "/img/defaultUser.png"
          ]
        "#delete_ava_person":
          attributes: [
            name: "style"
            observe: "HAS_TM_THUMBNAILPHOTO"
            onGet: (val) ->
              if val
                ""
              else
                "display: none"
          ]


      initialize: ->
        # Обрезанная картинка через crop
        @ava = null

        @children.add(
          new App.Views.Organization.PersonWorkstationAddEditGroups(
            collection            : @model.get("groups")
            personWorkstationItem : @model
          ), "groups"
        )

        @children.add(
          new App.Views.Organization.Contacts(
            collection: @model.get("contacts")
          ), "contacts"
        )

        @children.add(
          new App.Views.Organization.PersonWorkstationAddEditStatuses(
            collection : @model.get("status")
            personWorkstationItem : @model
          ), "statuses"
        )

        if @model.idAttribute is "PERSON_ID"
          @children.add(
            new App.Views.Organization.PersonAddEditWorkstations(
              collection: @model.get("workstations")
              person: @model
            ), "workstations"
          )

        else if @model.idAttribute is "WORKSTATION_ID"
          @children.add(
            new App.Views.Organization.WorkstationAddEditPersons(
              collection: @model.get("persons")
              workstation: @model
            ), "persons"
          )


      getTemplate: ->
        if @model.idAttribute is "PERSON_ID"
          "organization/person_add_edit"
        else if @model.idAttribute is "WORKSTATION_ID"
          "organization/workstation_add_edit"


      templateHelpers: ->
        cancel : App.t "global.cancel"
        confirm: App.t "global.save"


      deserializeModel: ->
        Backbone.Syphon.deserialize @, @model.toJSON(),
          exclude: ["unit_edit--mode"]


      onShow: ->
        @groups.show @children.findByCustom "groups"
        @contacts.show @children.findByCustom "contacts"
        @statuses.show @children.findByCustom "statuses"

        if @model.idAttribute is "PERSON_ID"
          @workstations.show @children.findByCustom "workstations"
        else if @model.idAttribute is "WORKSTATION_ID"
          @persons.show @children.findByCustom "persons"

        @_initSelect2OnTmManager()
        @_initStickit()

        self = @
        @ui.add_ava_to_person.fileupload
        # При выборе картинки
          add: ->
            modal = new App.Layouts.CropDialog(
              callback : (result) ->
                if result
                  self.ava = result
                  self.ui.ava_preview.prop "src", self.ava
                  self.model.set
                    "HAS_TM_THUMBNAILPHOTO" : 1
                self.ui.add_ava_to_person.val("")

              file      : @files[0]
              max_side  : 67
              title     : App.t 'crop-image.crop_image'
            )
            App.modal2.show modal

          autoUpload        : false
          replaceFileInput  : false


      onDestroy: ->
        @trigger "cancel:add:person:workstation:item"
        @trigger "cancel:edit:person:workstation:item"
        super


      onSavePersonWorkstationItem: ->
        type = Organization.reqres.request("get:content:entity:type")[0]
        unless helpers.can({action: 'edit', type: type})
          return

        if @model.isNew()
          current_view = App.Controllers.Organization.contentView.currentView
          current_entity = current_view.collection.type

          if current_entity is "persons"
            current_view.once "add:child", (view) =>
              @_uploadFile(view.model.id)

          else if current_entity is "workstations"
            App.Controllers.Organization.workstationsCollection.once "add", (model) =>
              @trigger "cancel:add:person:workstation:item"
        else
          if @model.type is "person"  and  @model.get("SOURCE") isnt "ad" and @model.get("SOURCE") isnt "dd"
            @_uploadFile()


      _initSelect2OnTmManager: ->
        paging_k = @model.collection.limit

        @ui.tm_manager.select2
          minimumInputLength: 3
          maximumInputLength: 1024
          multiple: false

          createSearchChoice: (term) ->
            id: term
            text: term

          ajax:
            url: "#{App.Config.server}/api/ldapPerson"
            data: (term, page) ->
              filter:
                DISPLAY_NAME: "#{term}*"
              limit: page * paging_k
              sort:
                DISPLAY_NAME: "asc"
              start: (page - 1) * paging_k
              with: ["real_group"]

            results: (data) ->
              results: _.map data.data, (item) ->
                id: item.DISPLAY_NAME
                text: item.DISPLAY_NAME
                managerId: item.PERSON_ID

          id: (data) -> data.id

          initSelection: (element, callback) =>
            data = {}
            if @model.get "TM_MANAGER"
              _.extend data,
                id: @model.get('TM_MANAGER')
                text: @model.get('TM_MANAGER')

            callback(data)

          formatSearching: "#{App.t('global.search')}..."

          formatInputTooShort: "#{App.t('form.hint.autocomplete')}..."

        @ui.tm_manager.on "select2-selecting", (e) =>
          @ui.tm_manager_id.val(e.choice.managerId)


      _initStickit: ->
        @stickit()


      _deleteAva: (e) ->
        e.preventDefault()

        App.Helpers.confirm
          title  : App.t 'organization.delete_ava_person'
          accept: =>
            @ava = null
            @model.set
              "HAS_TM_THUMBNAILPHOTO" : 0


      _uploadFile: (id = @model.id) ->
        @ui.add_ava_to_person?.fileupload(
          "send",
          files : if @ava? then App.Helpers.data_url_to_blob(@ava)
          url   : "#{App.Config.server}/api/ldapPerson/uploadImage?person_id=#{id}"
        )
        .success( ->
          model = App.Controllers.Organization.personsCollection.get(id)
          model.fetch
            success: ->
              App.Controllers.Organization.contentView.currentView.children.findByModel(model)?.render()
        )
        .always(
          => @trigger "cancel:add:person:workstation:item"
        )
