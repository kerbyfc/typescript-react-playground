Component = require 'component'

# settings module ldap view
#
class LdapView extends Component

  lol = true

  # render ldap view
  # @note there is a build in React interface
  # @return {Object} React Component
  #
  render: ->
    React.createElement(React.DOM.div, null, "LDAP VIEW")

module.exports = LdapView
