"use strict"

require "layouts/dialogs/confirm.coffee"
require "jquery-ui"
require "backbone.syphon"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

    # ## Данный класс представляет из себя один контакт в форме редактирования персоны/рабочей станции
    class App.Views.Organization.Contact extends Marionette.ItemView

      template  : "organization/person_workstation_add_edit_contact"

      tagName   : "li"

      className : "employeeExtendedItem"

      attributes: ->
        "data-selectable" : true

      triggers:
        "click"         : 'selected'

      modelEvents:
        "model_edited" : -> @render()

      deleteContact: ->
        @model.id = null
        @model.destroy()

    # ## Данный класс представляет из себя контакты в форме редактирования персоны/рабочей станции
    class App.Views.Organization.Contacts extends Marionette.CompositeView

      template: "organization/person_workstation_add_edit_contacts"

      childView: App.Views.Organization.Contact

      childViewContainer: "#person-workstation-contacts"

      ui:
        addContactForm     : "[data-add-contact-form]"
        addContactSwitcher : "[id^=employeeExtendedTab__form]"
        editContact        : "[data-edit-contact]"
        deleteContact      : "[data-delete-contact]"
        contactType        : "[name='CONTACT_TYPE']"
        saveButton         : "[data-save-contact]"

      templateHelpers: ->
        IDENTITY_TYPE: @options.collection.type

      childViewOptions: ->
        blocked: @options.blocked

      events :
        "click @ui.editContact"        : "show_edit"
        "click @ui.deleteContact"      : "show_delete"
        "click @ui.saveButton"         : "saveContact"
        "click [data-add-contact]"     : "_showContactForm"
        "click [data-reset-contact]"   : "_closeContactForm"
        "click @ui.addContactSwitcher" : "_showHideForm"

      collectionEvents:
        "add" : ->
          App.Common.ValidationModel::.unbind @
          @_closeContactForm()
        "change": ->
          @_updateToolbar()

      _makeSelectable: ->
        @$childViewContainer?.selectable
          filter : "[data-selectable]"

      onAddChild: ->
        @_makeSelectable()

      onRenderCollection: ->
        @_makeSelectable()

      _updateToolbar: ->
        selected = @getSelectedViews()
        models = _.map selected, (view) -> view.model
        hasNotTm = _.filter models, (model) -> model.get('SOURCE') isnt 'tm'

        if selected.length is 1 and not hasNotTm.length
          @ui.editContact.prop('disabled', false)
        else
          @ui.editContact.prop('disabled', true)

        if selected.length >= 1 and not hasNotTm.length
          @ui.deleteContact.prop('disabled', false)
        else
          @ui.deleteContact.prop('disabled', true)

      onChildviewSelected: ->
        @_updateToolbar()

      _showHideForm: ->
        @ui.addContactForm[0].reset()
        @$('[name="CONTACT_ID"]').val('')
        @$('[name="cid"]').val('')

        @ui.addContactForm.find('input').each (index, elem) ->
          $(elem).popover("destroy") if $(elem).data("bs.popover")

      _makeSelect2: ->
        @ui.contactType.select2 'destroy'

        @ui.contactType.select2
          minimumResultsForSearch: 100
          formatResult: (object, container, query) ->
            "<i class='icon _#{object.id} _sizeSmall'></i>#{object.text}"
          formatSelection: (object, container) ->
            "<i class='icon _#{object.id} _sizeSmall'></i>#{object.text}"

      onShow : ->
        @_updateToolbar()

      _showContactForm : (e) ->
        e?.preventDefault()

        @_makeSelect2()

        @ui.addContactSwitcher.click()

      _closeContactForm: ->
        @ui.addContactSwitcher.click()

      saveContact: (e) ->
        e?.preventDefault()

        data = Backbone.Syphon.serialize @
        if data.cid then @_editContact(data) else @_addContact(data)

      getSelectedViews : ->
        _ @$ ".ui-selected"
        .map (el) =>
          @$childViewContainer.find el
          .index()
        .map (i) =>
          @children.findByIndex i
        .value()

      show_edit : (e) ->
        e?.preventDefault()

        views = @getSelectedViews()

        if views.length is 1
          @_showContactForm()

          data = views[0].model.toJSON()
          data.action = 'edit'
          data.cid = views[0].model.cid

          Backbone.Syphon.deserialize @, data

          @_makeSelect2()

      show_delete : (e) ->
        e?.preventDefault()

        views = @getSelectedViews()

        if views.length
          contacts = _.map views, (view) -> view.model.get 'VALUE'
          App.Helpers.confirm
            title   : App.t 'menu.organization'
            data    : App.t "organization.contact_delete_question",
              contacts: contacts.join(', ')
            accept  : ->
              _.invoke views, "deleteContact"

      # TODO: Refactor to create a separate form view
      _editContact: (data) =>
        @model = @collection.get data.cid
        App.Common.ValidationModel::.bind @

        @model.editContact(data).done =>
          App.Common.ValidationModel::.unbind @
          @_closeContactForm()

      _addContact: (data) =>
        @_disableSaveButton()
        @listenToOnce @collection, 'add', @_enableSaveButton

        @model = new @collection.model()
        @model.collection = @collection
        App.Common.ValidationModel::.bind @
        @listenToOnce @model, 'validated:invalid', @_enableSaveButton

        @model.create_contact data

      _disableSaveButton: =>
        @ui.saveButton.attr "disabled": ""

      _enableSaveButton: =>
        @ui.saveButton.removeAttr "disabled"
