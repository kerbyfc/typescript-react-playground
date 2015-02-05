
session = require "core/session"
imports =
  Dropdown : require "dropdown"

helpers = require "core/helpers"

class AppLayoutHeaderMenu extends Component

  template: JSX.app_layout_header_menu

  resolveDropdownClass: (route) ->
    (location.href.match route) and "active" or ""

  extractRoutes: (routeComponents) ->
    _.reduce routeComponents, (mem, route) ->
      if name = route.props.name
        mem[route.props.name] = "i18n:#{route.props.name}"
      mem
    , {}

  logout: ->
    helpers.apiCall "logout",
      success: ->
        location.reload()

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    _.extend @, imports, Router,
      session: session

module.exports = AppLayoutHeaderMenu
