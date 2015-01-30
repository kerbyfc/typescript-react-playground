Component = require "component"
template  = require "./app_layout_header_menu-tmpl"
session   = require "session"

requiredComponents =
  Dropdown: require "dropdown"

class AppLayoutHeaderMenu extends Component

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

  extractRoutes: (routeComponents) ->
    _.reduce routeComponents, (mem, route) ->
      if name = route.props.name
        mem[route.props.name] = "i18n:#{route.props.name}"
      mem
    , {}

  ###*
   * @nodoc
   * @return {Object} - template locals
  ###
  locals: ->
    _.extend @, requiredComponents, Router,
      session: session

  ###*
   * @nodoc
   * @return {Void} - after component mount manipulations
  ###
  onMount: ->
    super

module.exports = AppLayoutHeaderMenu
