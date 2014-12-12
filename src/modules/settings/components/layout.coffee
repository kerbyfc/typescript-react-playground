Component = require 'component'

class SettingsLayout extends Component

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
