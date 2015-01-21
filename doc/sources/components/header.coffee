Component = require 'component'

class Header extends Component

  # @nodoc
  render: ->
    React.createElement(React.DOM.div, {"className": "header"},
      React.createElement(Link, {"to": "settings"}, "Settings")
    )

module.exports = Header
