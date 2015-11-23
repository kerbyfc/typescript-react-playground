"use strict"


module.exports = class LdapServersList extends App.Views.Controls.FancyTree

  template: "settings/ldap_servers_lists"

  className: "sidebar__content"

  behaviors:
    Toolbar:
      disableReadOnlyEdit: true
