Component = require "component"
template  = require "./app_layout-tmpl"

requiredComponents =
  AppLayoutHeader: require "app_layout_header"

class AppLayout extends Component

  template: template

  ###*
   * @nodoc
   * @return {Object} - template locals
  ###
  locals: ->
    _.extend @, requiredComponents, Router

module.exports = AppLayout
