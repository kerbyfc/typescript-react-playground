require "views/controls/tree.coffee"

module.exports = class Plugins extends App.Views.Controls.FancyTree

  # **************
  #  BACKBONE
  # **************
  className : "sidebar__content"

  ui: ->
    ui = super
    _.extend ui,
      add_plugin      : '[data-action="add_plugin"]'
      remove_plugin   : '[data-action="remove_plugin"]'

  _blockToolbar: ->
    @ui.add_plugin.prop "disabled", true
    @ui.remove_plugin.prop "disabled", true

  _updateToolbar: (selected) ->
    @_blockToolbar()

    @ui.add_plugin.prop "disabled", false

    if selected and selected.get('IS_SYSTEM') is 0
      @ui.remove_plugin.prop "disabled", false

  triggers :
    "click [data-action='add_plugin']"    : 'add_plugin'
    "click [data-action='remove_plugin']" : 'remove_plugin'

  # ****************
  #  MARIONETTE
  # ****************
  template  : "settings/plugins/plugins_list"

  onShow: ->
    super

    @listenTo @collection, "select", (selected) =>
      @_updateToolbar(selected)

