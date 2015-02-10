api = require "api"

class Session

  established: false

  ###*
   * Check if user is authenticated, processs coincident callback.
   *
   * @param  {Object} callbacks * callbacks for api call
   *
   * @return {Object} promise
  ###
  check: (callbacks = success: null, error: null) ->
    api.get 'user/check', @wrapLoginCallbacks callbacks

  wrapLoginCallbacks: (callbacks) ->
    @loginCallbacks =
      success: ({data}) =>
        @user = data
        callbacks.success? data
      error: =>
        @user = null
        callbacks.error? arguments...

  #
  # @param [ String ] priveledge or it's part
  # @return [ String|Undefined ] priveledge or undefined
  #
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
