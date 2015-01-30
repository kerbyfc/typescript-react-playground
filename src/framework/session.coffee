helpers = require "helpers"

AuthDialog = require "auth_dialog"

class Session

  established: false

  start: (@cb) ->
    @check()

  involve: (modules) ->
    @modules = _.extend modules...
    @

  check: (@cb = @cb) =>
    helpers.apiCall 'user/check'
      .error =>
        React.renderComponent <AuthDialog session=@ />, document.body
      .done @establish

  establish: ({ data }) =>
    @user = data
    @cb? this, @user, @modules

  checkAccess: (priv) =>
    priv = priv.slice 1 if priv[0] is "/"
    priv = priv.replace /\//g, '_'
    _.find @user.privileges, (_priv) ->
      _priv.PRIVILEGE_CODE.match priv

  ###*
   * Login
   * @param       { Object     } data     - user data
   * @option data { String     } username
   * @option data { String     } password
   * @return      { $.Deffered } deferred
  ###
  login: (data) ->
    helpers.apiCall 'login',
      type: "POST"
      data: data
      success: @establish

      # beforeSend: (a) ->
      #   a.setRequestHeader("X-Timezone", moment().format("Z")

# singleton
module.exports = new Session()
