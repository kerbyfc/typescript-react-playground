
api = require "api"

imports =
  Dropdown : require "dropdown"

class AppLayoutHeaderMenu extends App.Component

  template: App.JSX.app_layout_header_menu

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
    _.extend @, imports, App.Router,
      session: App.session

module.exports = AppLayoutHeaderMenu
