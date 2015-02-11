
###
 App class
###
class App

  _.extend App, window.App

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


  ###*
   * Method navigate
   * @param  {[type]} route [description]
   * @param  {[type]} title [description]
   * @return {[type]}       [description]
  ###
  navigate: (route, title) ->
    if history
      history.pushState null, "signin", "signin"
      history.go 1
    else
      location.hash = "/#{route}"

