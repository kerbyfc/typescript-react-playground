config = require 'config.json'

# misc helpers
class Helpers

  ###
  * Join url
  * @param  {String}  chunks... some
  * @return {String}            ret
  ###
  urlPath: (chunks...) ->
    chunks = for chunk in chunks
      chunk.replace /(^[\s]*\/)|(\/[\s]*$)/g, ''
    chunks.join '/'

  api: config.api[config.api_version]

  # form api url
  # @param path [ String ] url path
  # @return     [ String ] protocol + host + port + url path
  #
  apiUrl: (path) ->
    @api.protocol + "://" + @urlPath [
      @api.host
      @api.path
      path
    ]...

  # do api call
  #
  # @param url     [ Strign  ] url path
  # @param options [ Object  ] ajax options
  # @return        [ Promise ] jquery promise
  #
  apiCall: (url, options = {}) ->
    $.ajax _.extend options,
      url: @apiUrl url

  navigate: (route, title) ->
    if history
      history.pushState null, "signin", "signin"
      history.go 1
    else
      location.hash = "/#{route}"

# singleton
module.exports = new Helpers
