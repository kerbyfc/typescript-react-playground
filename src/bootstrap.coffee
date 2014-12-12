# import globals
require 'jquery'
require 'lodash'
require 'react'

global.app = require 'app'

# require
ApplicationLayout = require 'components/application_layout'

Settings = require 'modules/settings/bootstrap'

# form routers based on modules
routes =
  <Route name="app" path="/" handler={ApplicationLayout}>
    {Settings}
  </Route>

Router.run routes, (Handler) ->
  React.render <Handler/>, document.body
