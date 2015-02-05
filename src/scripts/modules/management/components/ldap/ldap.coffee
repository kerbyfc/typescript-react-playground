LdapStore = require "stores/ldap"

console.log LdapStore

class Ldap extends Component

  template: JSX.ldap

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
    @

  # @nodoc
  # @return [Void] - after component mount manipulations
  #
  onMount: ->
    super

module.exports = Ldap
