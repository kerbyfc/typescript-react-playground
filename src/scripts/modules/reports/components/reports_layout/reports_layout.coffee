
class ReportsLayout extends App.Component

  template: App.JSX.management_layout

  # @nodoc
  # @return [Object] - component props
  #
  defaultProps: ->
    {}

  # @nodoc
  # @return [Object] - component state
  #
  initState: ->
    {}

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
    App.Router

  # @nodoc
  # @return [Void] - after component mount manipulations
  #
  onMount: ->
    super

module.exports = ManagementLayout
