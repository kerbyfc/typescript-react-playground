# import globals
# require 'lodash'

window._      = require 'lodash'
window.$      = require 'jquery'
window.React  = require 'react'
window.Router = require 'react-router'

{ Route } = Router

# modules
Application = require 'components/layouts/application'
Settings    = require 'modules/settings/bootstrap'
Auth        = require 'modules/auth/bootstrap'

# form routers based on modules
routes =
  <Route name="app" path="/" handler={Application}>
    {Auth}
    {Settings}
  </Route>

# start user session
require 'session'
  .start ->
    Router.run routes, Router.HistoryLocation, (Handler) ->
      React.render <Handler/>, document.body
