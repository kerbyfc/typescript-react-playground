"use strict"

ChangePasswordDialog = require "views/settings/users_and_roles/change_password.coffee"
require "views/about.coffee"

App.module "Application",
  startWithParent: false
  define: (Application, App, Backbone, Marionette, $) ->

    class App.Views.HeaderView extends Backbone.Marionette.ItemView

      tagName: "nav"

      className: "header"

      template: "header"

      events:
        "click [data-action='logout']"            : "logout"
        "click [data-action='change_password']"   : "changePassword"
        "click [data-action='change_lang']"       : "setLanguage"
        "click [data-action='help']"              : "help"
        "click [data-action='about']"             : "about"

      templateHelpers:
        showMore: ->
          _.some [
            'protected'
            'organization'
            'policy'
            'lists'
            'settings'
            'crawler'
          ], (section) =>
            @can(url: section)

      about: (e) ->
        e.preventDefault()

        $.ajax
          type : 'GET'
          url : "#{App.Config.server}/api/checkVersion"
          dataType : 'json'
          success : (data) ->
            App.modal.show new App.Views.AboutDialog
              version: data.data.dbVersion

      help: (e) ->
        e.preventDefault()

        window.open "/documentation/#{App.Session.currentUser().get('LANGUAGE')}/html/8010996.html", 'open_window',
          'menubar, toolbar, location, directories, status, scrollbars, resizable,
          dependent, width=640, height=480, left=0, top=0'

      changePassword: (e) ->
        e.preventDefault()

        App.modal.show new ChangePasswordDialog
          title: App.t 'settings.users.change_password_title'
          model: App.Session.currentUser()

      setLanguage: (e) ->
        e.preventDefault()

        if $(e.currentTarget).parent().hasClass('active') then return

        user = App.Session.currentUser()

        user.save {'LANGUAGE': $(e.currentTarget).data('lang')},
          wait: true
          success: ->
            App.Helpers.confirm
              title: App.t 'settings.users.user_change_language'
              data: App.t 'settings.users.user_change_language_question'
              accept: ->
                location.reload()

      onShow: ->
        if App.Setting.get('product') is 'pdp'
          @$el.addClass 'pdp'

        App.LicenseManager.on 'license:users_counted', =>
          @render()

      logout: (e) ->
        e?.preventDefault()

        if App.Configuration.isEdited()
          App.Helpers.confirm
            title: App.t 'configuration.quit_title'
            data: App.t 'configuration.quit_question'
            accept: ->
              PNotify.removeAll()
              App.vent.trigger("auth:logout")
        else
          PNotify.removeAll()
          App.vent.trigger("auth:logout")
