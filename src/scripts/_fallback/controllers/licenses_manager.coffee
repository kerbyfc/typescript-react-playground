"use strict"

Licenses = require "models/settings/licenses.coffee"

App.module "Application.LicenseManager",
  startWithParent: true
  define: (LicenseManager, App, Backbone, Marionette, $) ->

    class LicenseManagerController extends Marionette.Controller

      initialize: ->
        # Получить лицензии с сервера
        @licenses = new Licenses.Collection()

        @licenses.fetch
          reset: true
          async: false
          success: =>
            activeLicenses = @licenses.getActive()
            @showLicenseMissedNotification = not activeLicenses.length

            @licenses.getActiveUsers().done (users) =>
              licensedUsers = activeLicenses[0]?.get('meta').users ? 1

              if users.data > ((100 + App.Config.userLimit) * licensedUsers) / 100
                @showLicenseUserViolationNotification = true
                @userViolateValue = Math.abs(licensedUsers - users.data)

              App.LicenseManager.trigger 'license:users_counted'

      getAllLicenses: ->
        @licenses

      getActiveLicenses: ->
        @licenses.getActive()

      getCurrentLicense: ->
        @licenses.getCurrentLicense()

      getNextLicense: ->
        @licenses.getNextLicense()

      getPrevLicense: ->
        @licenses.getPrevLicense()

      computeUnlicensedPeriod: (current, next) ->
        if current and next
          moment.range(current.getEndDate(), next.getBeginDate())

      getLicenseInterceptFeatures: ->
        Array::concat.apply [], _.pluck @licenses.getActive(), 'attributes.intercept_features'

      getLicenseTechnologyFeatures: ->
        Array::concat.apply [], _.pluck @licenses.getActive(), 'attributes.technology_features'

      getLicenseAutoupdateFeatures: ->
        Array::concat.apply [], _.pluck @licenses.getActive(), 'attributes.autoupdate_features'

      getLicensesActiveFeatures: ->
        Array::concat.apply [], _.pluck @licenses.getActive(), [
          'attributes.technology_features'
          'attributes.intercept_features'
          'attributes.autoupdate_features'
        ]

      hasInterceptFeature: (object_type, origin, protocol = '*') ->
        features = @getLicenseInterceptFeatures()

        _.any features, (feature) ->
          if (
            feature['object_type'] in ['*', object_type] and
            feature['protocol'] in ['*', protocol, 'NONE']
          )
            if origin and feature['origin'] not in [origin]
              return false

            return true

      hasTechnologyFeature: (locatedFeature) ->
        features = @getLicenseTechnologyFeatures()

        _.find features, (feature) ->
          feature['cas'] is locatedFeature

      hasAutoupdateFeature: (tech) ->
        features = @getLicenseTechnologyFeatures()

        _.find features, (feature) ->
          feature['tech_type'] is tech

    # Initializers And Finalizers
    # ---------------------------
    LicenseManager.addInitializer ->
      App.LicenseManager = new LicenseManagerController()

    LicenseManager.addFinalizer ->
      delete App.LicenseManager


# TODO: use commonjs with browserify instead in all cases
module.exports = App.LicenseManager
