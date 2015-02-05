
imports =
  AppLayoutHeader: require "app_layout_header"

class AppLayout extends Component

  template: JSX.app_layout

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    _.extend @, imports, Router

module.exports = AppLayout
