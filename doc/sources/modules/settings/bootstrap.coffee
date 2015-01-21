Layout = require './components/layouts/common'

Ldap   = require './components/ldap'
Users  = require './components/users'

"SOMEBODY"

{ Route } = Router

module.exports =
  React.createElement(Route, {"name": "settings", "handler": (Layout)},
    React.createElement(Route, {"name": "ldap", "handler": (Ldap)}),
    React.createElement(Route, {"name": "users", "handler": (Users)})
  )
