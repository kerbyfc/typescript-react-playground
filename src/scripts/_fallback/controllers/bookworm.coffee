"use strict"

models = require "models/services/bookworm.coffee"
require "views/bookworm/bookworm_unactive.coffee"

class BookwormController extends Marionette.Controller

  ###*
   * Create collections and event handlers
  ###
  initialize: ->
    # Признак наличия сервиса bookworm
    @active = null
    @dicts  = {}

    for item in models.collections
      name = item.name.toLowerCase()
      @dicts[name] = new item

    App.reqres.setHandler "bookworm", (name, id) =>
      return @dicts[name] unless id
      @dicts[name].get id

  ###########################################################################
  # PRIVATE

  ###*
   * Fetch all dictionaries
  ###
  _fetchDicts: ->
    _.map @dicts, (dict, name) ->
      new Promise (resolve, reject) ->
        dict.fetch
          reset: true
          success: (data) ->
            localStorage.setItem "bookworm:#{name}", JSON.stringify data
            resolve null
          error: (model, xhr, options) ->
            reject xhr

  ###*
   * Update state on fetch, start autoupdating
   * @param  {Error|Null} err
   * @param  {Array} results
  ###
  _onFetch: (err, results) =>
    if err and err.responseText is 'bookworm_not_found'
      @active = false
      @trigger 'bookworm:unactive'
    else
      @trigger 'bookworm:active' if @active is false
      @active = true
      localStorage.setItem "bookworm:timestamp", moment().toString()

    @timer ?= setInterval @fetch, 300000

  ###*
   * Get all data from local storage cache
  ###
  _getFromCache: ->
    for name, dict of @dicts
      if dict = localStorage.getItem "bookworm:#{name}"
        @dicts[name].reset JSON.parse dict

  ###########################################################################
  # PUBLIC

  ###*
   * Fetch all dictionaries
  ###
  fetch: =>
    timestamp = localStorage.getItem "bookworm:timestamp"

    # diff in minutes
    diff = moment().diff(moment(timestamp), "m")

    @promise = new Promise (resolve) =>
      unless timestamp and diff < App.Config.bookwormUpdateInterval

        Promise.all @_fetchDicts()
          .then =>
            @_onFetch()
            resolve()
      else
        @_getFromCache()
        _.defer resolve

    @promise

  ###*
   * Stop autoupdating
  ###
  stop: ->
    clearInterval @timer

  onReady: ->
    @fetching or new Promise (resolve) ->
      _.defer resolve

# singleton
module.exports = new BookwormController
