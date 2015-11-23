"use strict"

module.exports = class PoliciesStat extends App.Common.BackbonePagination

  model: Backbone.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/policyStat?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage

      url += $.param(url_params)

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      _.each @policies, (policy) ->
        url += "&filter[POLICY_ID][]=#{policy}"

      return url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 5
