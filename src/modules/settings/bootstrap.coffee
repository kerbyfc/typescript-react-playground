Layout = require './components/layouts/common'

# Ldap   = require './components/ldap'
Users  = require './components/users'

{ Route, RouteHandler } = Router

Component = require "component"

class Ldap extends Component

  render: ->
    <div>LDAP</div>


class Users extends Component

  render: ->
    <div>USERS</div>


class Management extends Component

  render: ->
    <RouteHandler />

module.exports = (session) ->
  [
    if session.checkAccess "management"

      <Route
        name="management"
        handler=Management
        >
        {[

          if session.checkAccess "management_settings_ldap"
            <Route
              name    = "ldap"
              key     = "ldap"
              handler = Ldap
              />

          if session.checkAccess "management_settings_access_users"
            <Route
              key     = "users"
              name    = "users"
              handler = Users
              />

        ]}
      </Route>
  ]
