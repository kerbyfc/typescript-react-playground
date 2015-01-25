Component = require 'component'

class AuthForm extends Component

  initState: ->
    login: ""

  # Test
  # @param e [Event] event
  #
  onLoginChanged: (e) ->
    @setState
      login: e.target.value

  # Render template
  # @param  [Object ] param  some parameter
  # @param  [Some   ] param2 second parameter
  # @return [String ]        template
  #
  render: (param, param2) ->
    <div className="no-layout">
      <div className="auth">
        <div className="auth--title"></div>
        <form className="auth--form form">
          <div className="form--row">
              <label className="form--label size-full" for="form--login">Логин:</label>
            <div className="form--elem">
              <input tabindex="1" type="text" name="username" data-i18n="[placeholder]login.login_placeholder" placeholder="Введите логин" value=@state.login onChange=@onLoginChanged />
            </div>
          </div>
          <div className="form--row">
            <label className="form--label size-full" for="form--password">
              Пароль:
            </label>
            <div className="form--elem">
              <input tabindex="2" type="password" name="password" data-i18n="[placeholder]login.password_placeholder" placeholder="Введите пароль">
            </div>
          </div>
          <div className="form--row submit">
            <button className="button button-success" data-action="login" tabindex="3" data-i18n="login.submit_button">
              Войти или нет
            </button>
          </div>
        </form>
      </div>
    </div>

module.exports = AuthForm
