Component = require "./base"

class View extends Component

  render: ->
    @template? _.extend {}, @, App.Router, @locals(), @imports

module.exports = View
