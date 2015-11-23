"use strict"

module.exports = class ProtectedDocuments extends App.Common.BackbonePagination

  model: Backbone.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/protectedDocumentStat?"

      url_params =
        start   : @currentPage * @perPage
        limit   : @perPage

      url += $.param(url_params)

      url += "&filter[START_TIME]=#{@start_date.unix()}" if @start_date
      url += "&filter[END_TIME]=#{@end_date.unix()}" if @end_date

      _.each @protected_documents, (document) ->
        url += "&filter[DOCUMENT_ID][]=#{document}"

      _.each @protected_catalogs, (catalog) ->
        url += "&filter[CATALOG_ID][]=#{catalog}"

      if @filter
        url += "&" + $.param(@filter)

      return url

    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 7
