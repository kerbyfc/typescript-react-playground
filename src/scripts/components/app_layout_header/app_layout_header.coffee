
imports =
  AppLayoutHeaderMenu: require "app_layout_header_menu"

class AppLayoutHeader extends Component

  template: JSX.app_layout_header

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    _.extend @, imports

module.exports = AppLayoutHeader
