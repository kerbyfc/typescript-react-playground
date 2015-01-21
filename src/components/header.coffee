Component = require 'component'

class Header extends Component

  # @nodoc
  render: ->
    <div className="header">
      <Link to="settings">Settings</Link>
    </div>

module.exports = Header
