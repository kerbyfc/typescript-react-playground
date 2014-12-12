class App

  config  : require 'config.json'
  helpers : require 'helpers'

  apiSetup: (options) ->
    $.ajaxSetup options

module.exports = new App
