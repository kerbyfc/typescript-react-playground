
class Input extends App.Component

  template: App.JSX.input

  # @nodoc
  # @return [Object] - component props
  #
  defaultProps: ->
    value : ""
    hint  : ""
    type  : "text"

  # @nodoc
  # @return [Object] - component state
  #
  initState: ->
    # set default type
    value: @props.value

  # @nodoc
# @return [Void] - before mount non-async manipulations
  #
  beforeMount: ->
    super

  # @nodoc
  # @return [Void] - state non-affecting manipulations
  #
  beforeUpdate: ->
    super

  # @nodoc
  # @return [Void] - state non-affection manipulations
  #
  onUpdate: ->
    super

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    @

  # @nodoc
  # @return [Void] - after component mount manipulations
  #
  onMount: ->
    super

  val: (value) ->
    # setter getter
    if value?
      @setState
        value: state.value
    else
      @state.value

  bind: (property) ->
    if _.has @state, property
      value: @state[property]
      requestChange: (value) =>
        state = {}
        state[property] = value
        @setState state

module.exports = Input
