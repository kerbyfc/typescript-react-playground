# globals
window._      = require 'lodash'
window.$      = require 'jquery'
window.React  = require 'react'
window.Router = require 'react-router'

{ Route, DefaultRoute } = Router

Layout = require 'app_layout'

###*
 * Singleton that starts the application.
###
class Bootstrapper

  ###*
   * construct bootstrapper
   * @param  {Array}   modules - list of modules
   * @param  {Session} session - session singleton
   * @return {Bootstraper}
  ###
  constructor: (mods, session) ->
    # start session and then...
    session.start ->

      # save route to build menu later
      # FIXME module should be an array of routes, but not a function
      # TODO routes should be filtered by session with user privileges (recursive)
      # (it should use some property for this e.g. "priveledge" or even "key")
      session.routes = for mod in mods
        do (mod) ->
          # involve module
          mod session

      # wrap route with handlers with application layout
      routes = <Route handler=Layout>
        { session.routes }
      </Route>

      # start application
      # Router.run routes, Router.HistoryLocation, (Handler) ->
      Router.run routes, (Handler) ->
        React.render <Handler/>, document.body

new Bootstrapper [

  # application modules
  require "modules/settings/bootstrap"
  require "modules/dashboard/bootstrap"

  # session
  ], require "session"
