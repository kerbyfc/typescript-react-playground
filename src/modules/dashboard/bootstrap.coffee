Component = require "component"

{ RouteHandler, Route, DefaultRoute, Redirect } = Router

class DashboardReporter extends Component

  render: ->
    <div>
      generate report
    </div>

class Dashboard extends Component

  render: ->
    <div>
      Dashboard component
      <RouteHandler />
    </div>

class DashboardWidgets extends Component

  render: ->
    <div>
      Widgets dialog
    </div>

module.exports = (session) ->
  [
    if session.checkAccess "dashboard"
      <Route
        key     = "dashboard"
        name    = "dashboard"
        handler = Dashboard >

        <Route
          key     = "create_report"
          name    = "create_report"
          handler = DashboardReporter />

        <DefaultRoute
          handler = DashboardWidgets />

        <Redirect from="/" to="dashboard" />
      </Route>
  ]
