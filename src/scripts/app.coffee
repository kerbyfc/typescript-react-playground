# globals

window._ = require "lodash"

# setup globals
_.extend window,
  $     : require "jquery"
  React : require "react"

App = window.App =
  # require config first
  config: require "config"

# then require core classes
_.extend App,
  Component : require "core/components/base"
  Store     : require "core/stores/base"
  JSX       : require "templates"
  Router    : require "react-router"

# then require user session
App.session = require "core/session"

# require base layouts
AuthLayout = require "auth_layout"
AppLayout  = require "app_layout"

{ Route } = App.Router

class App

  _.extend App, window.App

  # construct bootstrapper
  # @param  [Array]   modules - list of modules
  # @param  [Session] session - session singleton
  # @return [Bootstraper]
  #
  constructor: (modules) ->
    # start session and then...
    App.session.check

      success: ->

        # save route to build menu later
        # FIXME module should be an array of routes, but not a function
        # TODO routes should be filtered by session with user privileges (recursive)
        # (it should use some property for this e.g. "priveledge" or even "key")
        App.session.routes = for mod in modules
          do (mod) ->
            # involve module
            mod App.session

        # wrap route with handlers with application layout
        routes = App.Component.create Route, handler: AppLayout, App.session.routes

        # start application
        # Router.run routes, Router.HistoryLocation, (Handler) ->
        App.Router.run routes, (Handler) ->
          React.render App.Component.create(Handler), document.body

      error: ->
        React.render App.Component.create(AuthLayout), document.body

  navigate: (route, title) ->
    if history
      history.pushState null, "signin", "signin"
      history.go 1
    else
      location.hash = "/#{route}"

new App [
  # application modules
  require "modules/management/bootstrap"
]
