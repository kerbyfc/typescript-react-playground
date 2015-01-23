# import globals
require 'jquery'
require 'lodash'

global.React  = require 'react'
global.Router = require 'react-router'

{ Route } = Router

# modules
Application = require 'components/layouts/application'
Settings    = require 'modules/settings/bootstrap'
Auth        = require 'modules/auth/bootstrap'

# form routers based on modules
routes =
  React.createElement(Route, {"name": "app", "path": "/", "handler": (Application)},
    (Auth),
    (Settings)
  )

# start user session
require 'session'
  .start ->
    Router.run routes, Router.HistoryLocation, (Handler) ->
      React.render React.createElement(Handler, null), document.body
