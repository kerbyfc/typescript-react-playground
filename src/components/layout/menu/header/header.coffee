Component = require 'component'
Menu      = require './menu'

template = require './header-tmpl.js'

module.exports = class Header extends Component

  # @nodoc
  render: ->
    template
      Menu: Menu
