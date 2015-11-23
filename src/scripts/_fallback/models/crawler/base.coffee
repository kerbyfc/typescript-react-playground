"use strict"

module.exports = class CrawlerBase

  _lock_timer: null

  _lockRequest: ->
    throw new Error("Missing urlRoot property!") unless @urlRoot

    $.ajax(
      "#{@urlRoot}/#{@id}"
      type: "LOCK"
    )

  _unlockRequest: ->
    throw new Error("Missing urlRoot property!") unless @urlRoot

    $.ajax(
      "#{@urlRoot}/#{@id}"
      type: "UNLOCK"
    )

  lock: ->
    dfd = $.Deferred()

    if @isNew()
      dfd.resolve()
    else
      @_lockRequest()
      .done =>
        @_lock_timer = setInterval =>
          @_lockRequest()
        , 40000
        dfd.resolve()
      .fail (jqXHR, textStatus, errorThrown) -> dfd.reject(jqXHR, textStatus, errorThrown)

    dfd.promise()

  unlock: ->
    return if @isNew()

    if @_lock_timer
      clearInterval @_lock_timer
      @_lock_timer = null

      @_unlockRequest()
