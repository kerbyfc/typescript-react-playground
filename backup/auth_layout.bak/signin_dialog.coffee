Component = require "component"
FormBtn   = require "components/controls/form_btn"
FormInput = require "components/controls/form_input"

module.exports = class SignInDialog extends Component

  ###*
   * Index of elements focus order
   * @type {Number}
  ###
  tabindex: 0

  # @nodoc
  renderLoginInput: ->


  # @nodoc
  renderPasswordInput: ->


  # @nodoc
  renderSubmit: ->


  onSubmit: (e) ->
    e.preventDefault()

    @props.session.login
      username: @refs.login.val()
      password: @refs.password.val()

    .fail =>
      console.log "INVALID CREDENTIALS"

    false

  # @nodoc
  render: ->
    <div className="auth">
      <div className="auth--title"></div>
      <form className="auth--form form">
        {[
          @renderLoginInput()
          @renderPasswordInput()
          @renderSubmit()
        ]}
      </form>
    </div>



          FormInput

            <FormInput
          ref         = "login"
          name        = "login"
          tabindex    = ++@tabindex
          placeholder = "Введите логин"

          label = {
            text      : "Логин"
            className : "size-full"
          }
          />
          <FormInput
      ref         = "password"
      type        = "password"
      name        = "password"
      tabindex    = ++@tabindex
      placeholder = "Введите пароль"

      label = {
        text      : "Пароль"
        className : "size-full"
      }
      />
          @renderSubmit()
        ]}
      </form>
    </div>
