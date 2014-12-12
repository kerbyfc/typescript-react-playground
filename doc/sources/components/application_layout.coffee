Component = require 'component'

class ApplicationLayout extends Component

  initState: ->
    super

  render: ->
    React.createElement(React.DOM.div, null,
      React.createElement(Link, {"to": "settings"}, "settings"),
      React.createElement(RouteHandler, null)
    )

module.exports = ApplicationLayout
