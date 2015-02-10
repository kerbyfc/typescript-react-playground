ManagementLayout = require "management_layout"

Ldap  = require "ldap"
Users = require "users"

{ Route } = App.Router

module.exports = (session) ->
  [
    if session.checkAccess "management"

      App.Component.create Route,
        name    : "management"
        key     : "management"
        handler : ManagementLayout

        [
          if session.checkAccess "management_settings_ldap"
            App.Component.create Route,
              name    : "ldap"
              key     : "ldap"
              handler : Ldap

          if session.checkAccess "management_settings_access_users"
            App.Component.create Route,
              key     : "users"
              name    : "users"
              handler : Users
        ]
  ]
