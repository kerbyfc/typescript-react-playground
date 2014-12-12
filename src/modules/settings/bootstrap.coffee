Layout = require './components/layout'
Ldap   = require './components/ldap'
Users  = require './components/users'

routes = ['ldap', 'users']

views = {}

for route in routes
  views[route] = ''

module.exports =
  <Route name="settings" handler={Layout}>
    <Route name="ldap" handler={Ldap} />
    <Route name="users" handler={Users} />
  </Route>
