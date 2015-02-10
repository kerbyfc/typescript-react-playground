class View extends App.Component

  render: ->
    @template? _.extend {}, @, App.Router, @locals(), @imports

module.exports = View
