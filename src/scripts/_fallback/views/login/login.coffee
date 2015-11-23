"use strict"

module.exports = class LoginView extends Marionette.ItemView

  template: 'login/login'

  className: "auth"

  triggers:
    "click [data-action='login']" : "login"

  onShow: ->
    @$el.find('input:text:visible:first').focus()
