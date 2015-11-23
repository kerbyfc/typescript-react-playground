"use strict"

require "common/backbone-tree.coffee"

PluginBase = require 'models/settings/plugins/plugin_base.coffee'

class Plugin extends App.Helpers.virtual_class(
  App.Common.ModelTree
  PluginBase
)

  # **************
  #  BACKBONE
  # **************
  idAttribute : "PLUGIN_ID"

  urlRoot   : "#{App.Config.server}/api/plugin"


  # **********
  #  TREE
  # **********
  nameAttribute : "DISPLAY_NAME"

module.exports = class Plugins extends App.Common.CollectionTree

  # **************
  #  BACKBONE
  # **************
  model : Plugin

  url   : "#{App.Config.server}/api/plugin?merge_with[]=tokens"


  # **********
  #  TREE
  # **********
  config: ->
    extensions : []
