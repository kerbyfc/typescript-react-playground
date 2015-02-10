View = require "view"

imports =
  AppLayoutHeader: require "app_layout_header"

class AppLayout extends View

  displayName: "AppLayout"

  imports: imports
  template: App.JSX.app_layout

module.exports = AppLayout
