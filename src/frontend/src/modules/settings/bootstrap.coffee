Layout = require './components/layouts/common'

Ldap   = require './components/ldap'
Users  = require './components/users'

{ Route } = Router

module.exports =
  <Route name="settings" handler={Layout}>
    <Route name="ldap" handler={Ldap} />
    <Route name="users" handler={Users} />
  </Route>
