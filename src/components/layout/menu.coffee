Component    = require "component"
MenuLink     = require "./menu/link"
MenuDropdown = require "./menu/dropdown"

session      = require "session"

{ Link } = Router

module.exports = class Navigator extends Component

  renderLink: (route) ->
    <MenuLink>
      <Link className="main_nav--link" to=route.props.name >
        { route.props.name }
      </Link>
    </MenuLink>

  renderDropdown: (route) ->
    <MenuDropdown name=route.props.name>
      { @renderLinks route.props.children }
    </MenuDropdown>

  renderLinks: (routes) ->
    if routes
      links = for route, i in routes
        if route.props.name
          if route.props.children
            @renderDropdown route
          else
            @renderLink route
      _.compact links

  render: ->
    <nav className="main_nav">
      <ul className="main_nav--list">
        { @renderLinks modRoutes for modRoutes in session.routes }
      </ul>
    </nav>
