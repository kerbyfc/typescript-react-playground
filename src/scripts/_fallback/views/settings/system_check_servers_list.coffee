"use strict"

FancyTree = require "views/controls/fancytree/view.coffee"

module.exports = class SystemCheckServersList extends App.Views.Controls.FancyTree

  className: "sidebar__content"

  template: "settings/system_check_servers_list"
