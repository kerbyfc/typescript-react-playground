"use strict"

exports.Model = class StatTypesItem extends Backbone.Model

  idAttribute: "STATTYPE_ID"

  toJSON: ->
    data = super
    data.STATTYPEOPTIONS = JSON.stringify data.STATTYPEOPTIONS

    data

  parse: (response, options) ->
    response.STATTYPEOPTIONS = $.parseJSON response.STATTYPEOPTIONS
    return response


exports.Collection = class StatTypes extends Backbone.Collection

  model: exports.Model

  url: "#{App.Config.server}/api/stattype"

  initialize: ->
    @add [
      {
        STATTYPE_ID: 1
        STAT: 'threats'
        STATTYPEOPTIONS: {
          query: 'objectStat?group=VIOLATION_LEVEL'
        }

      }
      {
        STATTYPE_ID: 2
        STAT: 'users'
        STATTYPEOPTIONS: {
          query: 'objectStat?group=VIOLATION_LEVEL'
        }
      }
      {
        STATTYPE_ID: 3
        STAT: 'threats_stats'
        STATTYPEOPTIONS: {
          query: 'objectStat?group=VIOLATION_LEVEL'
          visualTypes: [
            'horizontal-bar',
            'grid'
          ]
        }
      }
      {
        STATTYPE_ID: 4
        STAT: 'selectionstats'
        STATTYPEOPTIONS: {

        }
      }
      {
        STATTYPE_ID: 5
        STAT: 'statusstats'
        STATTYPEOPTIONS: {

        }
      }
      {
        STATTYPE_ID: 6
        STAT: 'policystats'
        STATTYPEOPTIONS: {

        }
      }
      {
        STATTYPE_ID: 7
        STAT: 'protecteddocumentstats'
        STATTYPEOPTIONS: {

        }
      }
      {
        STATTYPE_ID: 8
        STAT: 'protectedcatalogstats'
        STATTYPEOPTIONS: {

        }
      }
    ]


###*
 * StatTypes instance.
###
exports.StatTypesInstance = new StatTypes()
