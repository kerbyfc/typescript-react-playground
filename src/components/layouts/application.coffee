Component = require 'component'
Btn       = require 'components/controls/btn'
Header    = require 'components/header'

session = require 'session'

{ Link, RouteHandler } = Router

# Component displays common layout
# of the whole application: header, menu, footer,
# main content, etc.
#
class Application extends Component

  # @nodoc
  render: ->
    <div>
      {session.established and <Header/>}
      <Btn />
      <RouteHandler/>
    </div>

module.exports = Application