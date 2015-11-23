"use strict"

exports.ThreatStat = class ThreatStat extends App.Common.BackbonePagination

  model: Backbone.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/objectStat?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage

      url += $.param(url_params)

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      url += "&total[]=RULE_GROUP_TYPE&total[]=VIOLATION_LEVEL"

      url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 5

  parse: (response) ->
    response = response.data or response

    return response if _.isEmpty response

    data = []

    for rule_group_type in ['Transfer', 'Copy', 'Placement']
      data.push _.assign {type: rule_group_type, High: 0, Medium: 0, Low: 0}, response[rule_group_type]

    data

exports.ThreatTimeline = class ThreatStat extends Backbone.Collection

  model: Backbone.Model

  url: ->
    url = "#{App.Config.server}/api/objectStat?group=VIOLATION_LEVEL"

    url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
    url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

    if @filter
      url += "&" + $.param(@filter)

    url
