"use strict"

module.exports = class LoginLayout extends Marionette.LayoutView

  template: "login_layout"

  regions:
    content : "#layout__content"

  onShow: ->
    if App.Setting.get('product').indexOf('pdp') isnt -1
      @$el.addClass 'pdp'
