require "pushstream"

SERVER_URL = App.Config.server

UPLOAD_URL = "#{SERVER_URL}/api/updateSystem/upload"
DISK_FREE_URL = "#{SERVER_URL}/api/updateSystem/diskFree"
CHECK_VERSION_URL = "#{SERVER_URL}/api/checkVersion"

PROTOCOL_WS = location.protocol is "https:"
HOST_WS = (SERVER_URL or location.origin).replace(/(http:\/\/|https:\/\/)/, "")
UPDATE_URL_WS = "/api/notify/listen"
UPDATE_CHANNEL = "service_update"

###*
 * @return {Object} Promise
###
getDiskFreeSpace = ->
  dfd = $.Deferred()

  $.when(
    $.ajax(DISK_FREE_URL),
    App.Configuration.fetch()
  ).then( (data) ->
    dfd.resolve(data[0].data.disk_free)
  , (error) ->
    dfd.reject(error)
  )
  dfd.promise()

###*
 * @return {Object} jqXHR
###
getVersion = ->
  $.ajax
    type    : 'GET'
    dataType  : 'json'
    url     : CHECK_VERSION_URL

updatesChannel = null
startListeningProgressUpdateChannel = ->
  if updatesChannel is null
    updatesChannel = new PushStream
      host: HOST_WS
      useSSL: PROTOCOL_WS
      urlPrefixWebsocket: UPDATE_URL_WS
      modes: "websocket"
    updatesChannel.addChannel(UPDATE_CHANNEL)
  updatesChannel

stopListeningProgressUpdateChannel = ->
  updatesChannel?.disconnect()
  updatesChannel = null

module.exports =
  REQUIRED_DISK_FREE_SPACE: 3221225472
  UPLOAD_URL: UPLOAD_URL
  getDiskFreeSpace: getDiskFreeSpace
  getVersion: getVersion
  startListeningProgressUpdateChannel: startListeningProgressUpdateChannel
  stopListeningProgressUpdateChannel: stopListeningProgressUpdateChannel
