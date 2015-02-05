helpers = require "core/helpers"

AuthDialog = require "auth_dialog"

class Session

  established: false

  # Entry point to application, application will start
  # after user session will be established
  # @param  [ Function   ] cb - callback
  # @return [ $.Deffered ] promise
  #
  start: (@cb) ->
    @check()

  # Check user is logged in
  # @param  [ Function   ] cb - callback
  # @return [ $.Deferred ] promise
  #
  check: (@cb = @cb) =>
    helpers.apiCall 'user/check'
      .error =>
        React.render React.createElement(AuthDialog, session: @), document.body
      .done @establish

  establish: ({ data }) =>
    @user = data
    @cb? this, @user, @modules

  # Check if user has priviledge to access functionality
  # @param [ String ] priveledge or it's part
  # @return [ String|Undefined ] priveledge or undefined
  #
  checkAccess: (priv) =>
    priv = priv.slice 1 if priv[0] is "/"
    priv = priv.replace /\//g, '_'
    _.find @user.privileges, (_priv) ->
      _priv.PRIVILEGE_CODE.match priv

  # Login
  # @param [ Object ] user data
  #   @option [ String ] username
  #   @option [ String ] password
  # @return [ $.Deffered ] deferred
  #
  login: (data) ->
    helpers.apiCall 'login',
      type: "POST"
      data: data
      success: @establish

      # beforeSend: (a) ->
      #   a.setRequestHeader("X-Timezone", moment().format("Z")

# singleton
module.exports = new Session()
