"use strict"

exports.Model = class UserAD extends Backbone.Model

  url_user_info: "#{App.Config.server}/api/ad/userinfo?user_id="

  idAttribute: "OBJECTGUID"

  initialize: ->
    super

    # @property [Object] slickgrid metadata
    @metadata = if @get 'IMPORTED'
      # mark as unselectable
      selectable: false
    else
      {}

  # get metadata for slickgrid plugin
  #
  # @return [Object] metadata
  #
  getMetadata: -> @metadata

exports.Collection = class UsersAD extends Backbone.Collection

  url: "#{App.Config.server}/api/ad/userSearch"

  model: exports.Model

  getLength: -> @length

  getItem: (i) -> @at i

  # get metadata for slickgrid plugin
  #
  # @param row [ Number ] row number
  # @return  [ Object ] metadata
  #
  getItemMetadata: (row) ->
    if model = @at(row)
      model.getMetadata()
    else
      {}

  # comparator "moves down" models
  # with attr IMPORTED = 1
  #
  # @param a [ UsersAD ] first model
  # @param b [ UsersAD ] second model
  # @return  [ Number   ] sorting decision
  #
  comparator: (a, b) ->
    ai = a.get 'IMPORTED'
    bi = b.get 'IMPORTED'
    an = a.get 'NAME'
    bn = b.get 'NAME'

    if ai is bi
      if an >= bn then 1 else -1

    else if ai and not(bi)
      1
    else
      -1
