AuthForm = require './components/auth_form'

{ Route } = Router

module.exports =
  <Route name="signin" handler={AuthForm}></Route>
