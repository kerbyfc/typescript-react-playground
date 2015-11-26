
imports =
  Input : require "input"
  Btn   : require "btn"

class AuthLayout extends App.Component

  displayName: "AuthLayout"
  template: App.JSX.auth_layout

  login: (e) ->
    e.preventDefault()

    App.session.login
      username: @refs.login.val()
      password: @refs.password.val()

    .fail =>
      console.log "INVALID CREDENTIALS"

module.exports = AuthLayout
