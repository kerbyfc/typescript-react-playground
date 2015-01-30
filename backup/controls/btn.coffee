Component = require 'component'

# common button control
module.exports = class Btn extends Component

  # Get text
  # @return [String] button text
  #
  renderText: ->
    @props.text or "Submit"

  # @nodoc
  render: ->
    <button {...@props}>
      { @renderText() }
    </button>

