"use strict"

module.exports = class StatusesStat extends App.Common.BackbonePagination

  model: Backbone.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/statusStat?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage

      url += $.param(url_params)

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      return url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 5
