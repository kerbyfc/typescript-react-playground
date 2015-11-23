Component = require("component")

class View extends Component

  render: ->
    @template? _.extend {}, @, app.Router, _.result(@, 'templateHelpers'), @imports

module.exports = View
