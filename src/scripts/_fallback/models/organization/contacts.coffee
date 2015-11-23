"use strict"

require "layouts/dialogs/confirm.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Models.Organization ?= {}

    class App.Models.Organization.Contact extends App.Common.ValidationModel

      initialize: -> @validation = {}

      defaults :
        IDENTITY_SOURCE : "tm"

      idAttribute: "CONTACT_ID"

      urlRoot: "#{App.Config.server}/api/ldapContact/"

      labels:
        "VALUE" : App.t 'form-fields.contactValue'

      _contact_exists_inline: (crazy_php_error) ->
        is_exists = true
        must_uniq = ["VALUE", "CONTACT_TYPE", "IDENTITY_ID"]

        _.forOwn crazy_php_error, (val, key) ->
          unless key in must_uniq
            is_exists = false

          if (
            not _.isArray val  or
            val.length isnt 1  or
            val[0] isnt "unique"
          )
            is_exists = false

          is_exists

        if is_exists
          exists_model = @collection.find (model) =>
            model isnt @  and
            model.attributes.VALUE is @attributes.VALUE  and
            model.attributes.CONTACT_TYPE is @attributes.CONTACT_TYPE

          @collection.trigger "this_contact_exists",
            @collection.indexOf exists_model

      _check_contact_exists: ->
        $.ajax @urlRoot,
          data:
            filter :
              CONTACT_TYPE  : @get "CONTACT_TYPE"
              VALUE         : @get "VALUE"
            limit : 1

      _prepare_validation: (data) ->
        @validation.VALUE = {
          required: true
          fn: (value, attr, computedState) ->
            is_exists = {}
            {
              CONTACT_TYPE    : is_exists.CONTACT_TYPE
              VALUE           : is_exists.VALUE
            } = computedState

            # Ищем дубликат в коллекции
            duplicate = @collection.where(is_exists)

            # Если нашли дубликат
            if duplicate.length and @ isnt duplicate[0]
              return App.t 'organization.user_contact_exist_validation_error'
        }

        switch data.CONTACT_TYPE
          when "mobile", "phone"
            @validation.VALUE.phone = true
          when "email"
            @validation.VALUE.email = true
          when "ip"
            @validation.VALUE.ip = true
          when "dnshostname"
            @validation.VALUE.dns = true

      create_contact: (data) ->
        @_prepare_validation(data)

        if @set data, {validate: true}
          model_with_contacts = App.Controllers.Organization.contentView.currentView.collection.find (model) =>
            model.get("contacts") is @collection

          model_with_contacts ?= App.Controllers.Organization.groupsCollection.find (model) =>
            model.get("contacts") is @collection

          model_with_contacts ?= @collection

          delete data.CONTACT_ID
          delete data.action

          @_check_contact_exists().success (resp) =>
            _add_new_contact = =>
              @collection.add(
                _.extend(
                  data

                  IDENTITY_ID     : model_with_contacts.id
                  IDENTITY_SOURCE : model_with_contacts.get "SOURCE"
                  IDENTITY_TYPE   : model_with_contacts.type
                  SOURCE          : 'tm'

                  (orig_val, new_val) ->
                    if new_val?
                      new_val
                    else
                      orig_val
                )
              )

            if resp.totalCount
              App.Helpers.confirm
                title   : App.t "menu.organization"
                data    : App.t "contacts.contact_exists_for_some"
                accept  : _add_new_contact
            else
              _add_new_contact()

      edit_contact: (data) ->
        deferred = $.Deferred()

        @_prepare_validation(data)

        if @set data, {validate: true}
          # Если данные валидны проверяем есть ли такой контакт у кого-то еще
          @_check_contact_exists()
          .success (resp) =>
            if resp.totalCount
              App.Helpers.confirm
                title: App.t "menu.organization"
                data  : App.t "contacts.contact_exists_for_some"
                accept: =>
                  deferred.resolve()
                  @trigger "model_edited"
                reject: => @set @previousAttributes()
            else
              deferred.resolve()
              @trigger "model_edited"
          .fail ->
            deferred.reject()
        else
          deferred.reject()

        deferred

    class App.Models.Organization.Contacts extends Backbone.Collection

      url: "#{App.Config.server}/api/ldapContact/"

      model: App.Models.Organization.Contact

      constructor: (models, options = {}) ->
        super

        @type = options.type
