Component = require 'component'

{ Link, RouteHandler } = Router

# settings module main layout
#
class SettingsLayout extends Component

  # @nodoc
  render: ->
    React.createElement(React.DOM.div, null, """
      SETTIGNS
""", React.createElement(React.DOM.ul, null,
        React.createElement(React.DOM.li, null,
          React.createElement(Link, {"to": "ldap"}, "Ldap settings"),
          React.createElement(Link, {"to": "users"}, "Users settings")
        )
      ),
      React.createElement(RouteHandler, null)
    )

module.exports = SettingsLayout
