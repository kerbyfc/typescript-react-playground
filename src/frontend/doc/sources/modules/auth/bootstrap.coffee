AuthForm = require './components/auth_form'

{ Route } = Router

module.exports =
  React.createElement(Route, {"name": "signin", "handler": (AuthForm)})
