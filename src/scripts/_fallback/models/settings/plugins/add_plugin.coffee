"use strict"

PluginBase = require 'models/settings/plugins/plugin_base.coffee'

module.exports = class AddPlugin extends PluginBase

  # **************
  #  BACKBONE
  # **************
  urlRoot : "#{App.Config.server}/api/plugin/install"

  # **************
  #  PRIVATE
  # **************
  checkArchive: (file) ->
    data = new FormData()
    data.append "file", file

    @save null,
      contentType : false
      data        : data
      processData : false
      url         : "#{App.Config.server}/api/plugin/check"

  sendData: (file) ->
    data = new FormData()
    data.append "file", file

    @save null,
      contentType : false
      data        : data
      processData : false
