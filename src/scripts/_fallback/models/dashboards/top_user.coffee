"use strict"

module.exports = class UserStats extends App.Common.BackbonePagination

  model: Backbone.Model

  paginator_core:
    url: ->

      url = "#{App.Config.server}/api/senderStat?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage

      url += $.param(url_params)

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      _.each @user_groups, (user_group) ->
        url += "&filter[PARENT_GROUP_ID][]=#{user_group}"

      _.each @user_statuses, (user_status) ->
        url += "&filter[STATUS][]=#{user_status}"

      if @filter
        url += "&" + $.param(@filter)

      return url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 5

  parse: (response) ->
    if @top and @top < response.totalCount
      response.totalCount = @top

    @totalPages = Math.ceil(response.totalCount / @perPage)

    data = _.take response.data, response.totalCount

    return data
