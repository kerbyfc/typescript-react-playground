Component    = require 'component'
SignInDialog = require './signin_dialog'

###*
 * Authorization layout. At the moment contains nothing,
 * except authorization form
###
module.exports = class AuthLayout extends Component

  # @nodoc
  render: ->
    <div className="no-layout">
      <SignInDialog
        session = @props.session
        />
    </div>
