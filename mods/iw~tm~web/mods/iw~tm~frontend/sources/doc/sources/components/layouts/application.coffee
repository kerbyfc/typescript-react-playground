Component = require 'component'
Btn       = require 'components/controls/btn'
Header    = require 'components/header'

session = require 'session'

{ Link, RouteHandler } = Router

# Component displays common layout
# of the whole application: header, menu, footer,
# main content, etc.
#
class Application extends Component

  # @nodoc
  render: ->
    React.createElement(React.DOM.div, null,
      (session.established and React.createElement(Header, null)),
      React.createElement(Btn, null),
      React.createElement(RouteHandler, null)
    )

module.exports = Application
