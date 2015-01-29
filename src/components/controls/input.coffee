Component = require "component"

###*
 * Text/password/date input component
###
module.exports = class Input extends Component

  # @nodoc
  initState: ->
    @props.type ?= "text"
    {}

  val: ->
    @getDOMNode().getElementsByTagName("input")[0].value

  # @nodoc
  render: ->
    <input ref="input" {...@props} />
