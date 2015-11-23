"use strict"

LoginView = require "views/login/login.coffee"
LoginLayout = require "layouts/login.coffee"

App.module "Login",
  startWithParent: false
  define: (Login, App, Backbone, Marionette, $) ->

    class LoginController extends Marionette.Controller

      start: ->
        layout = new LoginLayout
        view = new LoginView()

        # Рендерим Login layout
        App.main.show layout
        layout.content.show view

        user = App.Session.currentUser()

        @listenTo user, 'login:failed', (response_text) ->
          PNotify.removeAll()

          switch response_text
            when "system is update"
              error = App.t "login.system_is_update"
            when "username_or_password_invalid"
              # Show default message for security reason
              error = App.t "login.login_failed_message"
            when "unknown_identity"
              # Show default message for security reason
              error = App.t "login.login_failed_message"
            when "user_deleted"
              error = App.t "login.user_deleted"
            when "user_disabled"
              error = App.t "login.user_disabled"
            else
              error = App.t "login.login_failed_message"

          App.Notifier.showError
            text: error
            delay: 4000

        @listenTo view, "login", (data) ->
          data = Backbone.Syphon.serialize(data.view)

          user.login(data)

    # Initializers And Finalizers
    # ---------------------------
    Login.addInitializer ->
      App.Controllers.Login = new LoginController()
      App.Controllers.Login.start()

    Login.addFinalizer ->
      App.Controllers.Login.destroy()
      delete App.Controllers.Login
