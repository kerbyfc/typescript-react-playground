Component = require 'component'

{ Link, RouteHandler } = Router

# settings module main layout
#
class SettingsLayout extends Component

  # @nodoc
  render: ->
    <div>
      SETTIGNS
      <ul>
        <li>
          <Link to="ldap">Ldap settings</Link>
          <Link to="users">Users settings</Link>
        </li>
      </ul>
      <RouteHandler/>
    </div>

module.exports = SettingsLayout
