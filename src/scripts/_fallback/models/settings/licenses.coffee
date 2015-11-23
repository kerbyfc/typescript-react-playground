"use strict"

require "common/backbone-tree.coffee"

exports.Model = class License extends App.Common.ModelTree

  urlRoot: "#{App.Config.server}/api/license"

  type: 'license'

  islock: (data) ->
    data = action: data if _.isString data
    data.action = "edit" if data.action is "request_license"
    super data

  getName: ->
    @get 'issue_date'

  isEnabled: ->
    @isActive()

  isActive: ->
    @getRange().contains(moment())

  isReserved: ->
    @getBeginDate().isAfter(moment())

  isUnlimited: ->
    @getRange().diff('days') > 1824

  parse: (response) ->
    response = super
    response.id = response.fingerprint

    response.technology_features = _.filter response.features, (feature) ->
      _.has(feature, 'cas')

    response.intercept_features = _.filter response.features, (feature) ->
      _.has(feature, 'protocol') and _.has(feature, 'object_type')

    response.autoupdate_features = _.filter response.features, (feature) ->
      _.has(feature, 'data_type') and _.has(feature, 'tech_type')

    response

  getBeginDate: ->
    moment(@get('issue_date'))

  getEndDate: ->
    @getBeginDate().clone().add(@get('active_days'), 'days')

  getRange: ->
    moment.range(@getBeginDate(), @getEndDate())

  isAboutEnds: ->
    moment.range(moment(), @getEndDate()).diff('days') < 7

exports.Collection = class Licenses extends App.Common.CollectionTree

  model: exports.Model

  url: "#{App.Config.server}/api/license"

  toolbar: ->
    request_license: (selected) =>
      if @length is 0 then return true
      false

  islock: (data) ->
    data = action: data if _.isString data
    data.action = "edit" if data.action is "request_license"
    super data

  parseLicense: (licenseData) ->
    $.ajax
      type : 'POST'
      url : "#{@url}/parse"
      data: licenseData

  config: ->
    debugLevel : 0
    extensions : []

  comparator: (item) ->
    moment(item.get('issue_date')).unix()

  getActive: ->
    @filter (license) ->
      license.isActive()

  getCurrentLicense: ->
    @find (license) ->
      license.isActive()

  getNextLicense: ->
    currentLicense = @getCurrentLicense()
    if currentLicense
      @at(@indexOf(currentLicense) + 1)
    else
      @find (license) ->
        license.getBeginDate().isAfter(moment())

  getPrevLicense: ->
    currentLicense = @getCurrentLicense()
    if currentLicense
      @at(@indexOf(currentLicense) - 1)
    else
      _.find @models.reverse(), (license) ->
        license.getBeginDate().isBefore(moment())

  getActiveUsers: ->
    $.ajax
      url: "#{App.Config.server}/api/senderStat/count"
      headers:
        unabortable: true

  getLatestLicensee : ->
    @max (model) ->
      model.getEndDate().unix()
    .get "licensee"
