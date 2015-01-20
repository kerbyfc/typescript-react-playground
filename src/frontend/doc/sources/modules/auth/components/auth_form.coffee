Component = require 'component'

class AuthForm extends Component

  render: (param) ->
    React.createElement(React.DOM.div, null, "Auth form")

module.exports = AuthForm
