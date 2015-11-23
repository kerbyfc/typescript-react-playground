"use strict"

class Token extends Backbone.Model

  # **************
  #  BACKBONE
  # **************
  idAttribute : "USER_ID"

  regenerate: ->
    @save null, patch: true, url: "#{App.Config.server}/api/token/regenerate/#{@id}"

module.exports = class Tokens extends Backbone.Collection

  # **********
  #  DATA
  # **********
  plugin_id : null

  # *************
  #  PRIVATE
  # *************
  create: ->
    super
      PLUGIN_ID : @plugin_id
      PROVIDER  : "TOKEN"
    ,
      wait : true

  # **************
  #  BACKBONE
  # **************
  model : Token

  url   : "#{App.Config.server}/api/token"
