###*
 * Base api class
###
class Api

  ###*
   * To be implemented
   *
   * @abstruct
   * @type {String}
  ###
  api: null

  ###*
   * Form api url
   *
   * @param  {String} path * url path
   *
   * @return {String} resolve url path
  ###
  apiUrl: (path) ->
    @api.protocol + "://" + @urlPath [
      @api.host
      @api.path
      path
    ]...

  ###*
   * Join url
   *
   * @param  {Array<String>|String}  chunks... * path(s)
   *
   * @return {String} ret * resolved path
  ###
  urlPath: (chunks...) ->
    chunks = for chunk in chunks
      chunk.replace /(^[\s]*\/)|(\/[\s]*$)/g, ''
    chunks.join '/'

  ###*
   * do api call
   *
   * @param  {String} url * url path
   * @param  {Object} options * ajax options
   *
   * @return {Object} promise
  ###
  call: (url, options = {}) ->
    if options.data
      options.data = JSON.stringify options.data
    $.ajax _.extend options,
      dataType: "json"
      url: @apiUrl url

  get: (url, options = {}) ->
    @call url, _.extend options, type: "GET"

  post: (url, options = {}) ->
    # TODO add validation there (data existace)
    @call url, _.extend options, type: "POST"

module.exports = Api
