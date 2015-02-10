
imports =
  Input : require "input"
  Btn   : require "btn"

class AuthLayout extends App.Component

  displayName: "AuthLayout"
  template: App.JSX.auth_layout

  # @nodoc
  # @return [Object] - component props
  #
  defaultProps: ->
    {}

  # @nodoc
  # @return [Object] - component state
  #
  initState: ->
    {}

  # @nodoc
  # @return [Void] - before mount non-async manipulations
  #
  beforeMount: ->
    super

  # @nodoc
  # @return [Void] - state non-affecting manipulations
  #
  beforeUpdate: ->
    super

  # @nodoc
  # @return [Void] - state non-affection manipulations
  #
  onUpdate: ->
    super

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    imports

  # @nodoc
  # @return [Void] - after component mount manipulations
  #
  onMount: ->
    super

  login: (e) ->
    e.preventDefault()

    App.session.login
      username: @refs.login.val()
      password: @refs.password.val()

    .fail =>
      console.log "INVALID CREDENTIALS"

module.exports = AuthLayout
