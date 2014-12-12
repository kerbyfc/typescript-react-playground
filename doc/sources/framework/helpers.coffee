class Helpers

  # form api url
  # @param url [ String ] url path
  # @return    [ String ] protocol + host + port + url path
  #
  apiUrl = (url) ->
    [
      app.config.apiUrl.replace /\/$/, ''
      url
    ].join '/'


  # do api call
  #
  # @param url     [ Strign  ] url path
  # @param options [ Object  ] ajax options
  # @return        [ Promise ] jquery promise
  #
  apiCall: (url, options = {}) ->
    $.ajax _.extend options,
      url: apiUrl url

module.exports = new Helpers
