Component = require 'component'

# common button control
class Btn extends Component

  # @nodoc
  render: ->
    React.createElement(React.DOM.div, {"className": "btn"}, "Button")

module.exports = Btn
