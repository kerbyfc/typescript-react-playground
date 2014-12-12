Component = require 'component'

class ApplicationLayout extends Component

  initState: ->
    super

  render: ->
    <div>
      <Link to="settings">settings</Link>
      <RouteHandler/>
    </div>

module.exports = ApplicationLayout
