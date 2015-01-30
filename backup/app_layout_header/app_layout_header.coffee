Component = require "component"
template  = require "./app_layout_header-tmpl"

Menu = require "app_layout_header_menu"

class AppLayoutHeader extends Component

  template: template

  ###*
   * @nodoc
   * @return {Object} - component props
  ###
  defaultProps: ->
    {}

  ###*
   * @nodoc
   * @return {Object} - component state
  ###
  initState: ->
    {}

  ###*
   * @nodoc
   * @return {Void} - before mount non-async manipulations
  ###
  beforeMount: ->
    super

  ###*
   * @nodoc
   * @return {Void} - state non-affecting manipulations
  ###
  beforeUpdate: ->
    super

  ###*
   * @nodoc
   * @return {Void} - state non-affection manipulations
  ###
  onUpdate: ->
    super

  ###*
   * @nodoc
   * @return {Object} - template locals
  ###
  locals: ->
    Menu: Menu

  ###*
   * @nodoc
   * @return {Void} - after component mount manipulations
  ###
  onMount: ->
    super

module.exports = AppLayoutHeader
