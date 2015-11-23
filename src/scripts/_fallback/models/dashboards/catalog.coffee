"use strict"

module.exports = class App.Models.Protected.CatalogStat extends App.Common.BackbonePagination

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/protectedCatalogStat?start=#{@currentPage * @perPage}&limit=#{@perPage}"

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      _.each @protected_catalogs, (catalog) ->
        url += "&filter[CATALOG_ID][]=#{catalog}"

      if @filter
        url += "&" + $.param(@filter)
      url

    dataType: "json"

  paginator_ui:
    firstPage   : 0
    currentPage : 0
    perPage     : 7
