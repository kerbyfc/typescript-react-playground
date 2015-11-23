api = require "./api.coffee"

class Session

  established: false

  _showLoginForm = ->
    React.render AppLayout.create(AuthLayout), document.body

  _startRouting = ->
    routes = module(session) for module in modules

    # wrap route with handlers with application layout
    routes = AppLayout.create Router.Route, handler: AppLayout, routes

    Router.run routes, (Handler) ->
      React.render AppLayout.create(Handler), document.body

  start: (modules) ->
    @check()
      .done (response) =>
        @user = response.data
        _startRouting()
      .fail =>
        @user = null
        _showLoginForm()

  ###*
   * Check if user is authenticated, processs coincident callback.
   * @param  {Object} options
   * @return {Object} promise
  ###
  check: (options = {}) ->
    api.get 'user/check', options

  wrapLoginCallbacks: (options) ->
    @loginCallbacks =

      success: ({data}) =>
        @user = data

      error: =>
        @user = null

  ###*
   * Check if user has priviledge to access functionality
   *
   * @param  {String} priv * priveledge
   *
   * @return {Boolean} accessability flag
  ###
  checkAccess: (priv) =>
    priv = priv.slice 1 if priv[0] is "/"
    priv = priv.replace /\//g, '_'
    _.find @user.privileges, (_priv) ->
      _priv.PRIVILEGE_CODE.match priv

  ###*
   * Login user
   *
   * @param  {Object} data * loging & pass
   *
   * @return {Object} promise
  ###
  login: (data) ->
    api.post 'login', _.extend @loginCallbacks,
      data: data

      # beforeSend: (a) ->
      #   a.setRequestHeader("X-Timezone", moment().format("Z")

# singleton
module.exports = new Session()
