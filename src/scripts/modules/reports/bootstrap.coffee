Component     = require "component.coffee"
ReportsLayout = require "./components/reports_layout/reports_layout.coffee"

module.exports = Component.create(React.Route, {
  name    : "reports"
  key     : "reports"
  handler : ReportsLayout
});
