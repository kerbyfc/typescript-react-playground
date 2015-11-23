"use strict"

EmptyMessage = require("views/controls/empty_message.coffee")

###*
 * Licenses List renderer
###
exports.List = class LicenseList extends App.Views.Controls.FancyTree

  className: "sidebar__content"

  template: "settings/license_list"

  fill_email: ->
    """
      mailto:support@infowatch.com?
      subject=#{ App.t "settings.license.license_request" }&
      body=
      #{ App.t "settings.license.license_company" }:
      %0A
      #{ @collection.getLatestLicensee() }
      %0A
      #{ encodeURI App.t "settings.license.not_remove_licensee" }
      %0A%0A
      #{ encodeURI App.t "settings.license.more_to_license_request" }
    """

  behaviors :
    Toolbar :
      clearSelectionOnDelete: true


###*
 * License Item renderer
###
exports.License = class LicenseInfo extends Marionette.ItemView

  template: "settings/license"

  className: "content"

  templateHelpers: ->
    status              : if @model.isActive() then 'active' else if @model.isReserved() then 'reserved' else 'unactive'
    license_end_date    : @_getEndDate()
    object_type_codes   : _.groupBy App.request('bookworm', 'event').toJSON(), 'mnemo'
    protocols           : _.groupBy App.request('bookworm', 'protocol').toJSON(), 'mnemo'

  _getEndDate: ->
    if @model.isUnlimited()
      App.t 'settings.license.unlimited_license'
    else
      moment(@model.get 'issue_date').add('days', @model.get 'active_days').format('LL')


###*
 * Renders when there is no any licenses in TM
###
exports.EmptyList = class LicenseListEmpty extends EmptyMessage

  key: 'settings.license.list_empty'


###*
 * Renders when no license is selected
###
exports.EmptyLicense = class EmptyLicense extends EmptyMessage

  key: 'settings.license.license_empty'
