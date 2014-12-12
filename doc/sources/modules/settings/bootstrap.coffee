Layout = require './components/layout'
Ldap   = require './components/ldap'
Users  = require './components/users'

routes = ['ldap', 'users']

views = {}

for route in routes
  views[route] = ''

module.exports =
  React.createElement(Route, {"name": "settings", "handler": (Layout)},
    React.createElement(Route, {"name": "ldap", "handler": (Ldap)}),
    React.createElement(Route, {"name": "users", "handler": (Users)})
  )
