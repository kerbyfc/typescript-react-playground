"use strict"

require "pushstream"
Roles = require "models/settings/role.coffee"
require "models/settings/user.coffee"

Scopes = require "models/settings/scope.coffee"



useSSL = (location.protocol.match(/^https/)? or App.Config.server.match(/^https/)?)
server = (App.Config.server or location.origin).replace(/(http:\/\/|https:\/\/)/, "")
protocol = if useSSL then "wss" else "ws"
broadcastSocket = protocol + "://" + server + "/api/notify/listen/broadcast"

productAbilityList =
  "settings/setup"  : ["tmae", "tmas"]
  "settings/update" : ["tmae", "tmas"]

exports.Model = class User extends App.Common.ValidationModel

  idAttribute: "USER_ID"

  type: 'user'

  predefinedUserTypes: [ 3, 4 ]

  urlRoot: "#{App.Config.server}/api/user"

  defaults:
    PROVIDER                    : "PASSWORD"
    LANGUAGE                    : 'rus'
    STATUS                      : 0
    VISIBILITY_AREA_CONDITION   : ''
    privileges                  : []

  validation:
    PASSWORD_CONFIRMATION: [
      equalTo : "PASSWORD"
      msg: 'settings.users.password_confirm_error'
    ]
    PASSWORD: [
      pattern: /^\S*(?=\S{8,})(?=\S*[a-z])(?=\S*[A-Z])(?=\S*[\d])(?=\S*[\W])\S*$/
      msg: 'settings.users.password_validation_error'
    ]
    EMAIL: [
      pattern: "email"
      required: false
      msg: "settings.users.email_validation_error"
    ]
    USERNAME: [
      required: true
      msg: 'settings.users.login_validation_error'
    ,
      not_unique_field: true
      msg: 'settings.users.login_uniq_validation_error'
    ]
    DISPLAY_NAME: [
      required: true
      msg: 'settings.users.fullname_validation_error'
    ]

  initialize: ->
    @_updateOwner = false

  login: (data) ->
    $.ajax
      type: 'POST'
      headers:
        HTTP_X_TIMEZONE: moment().format('Z')
      url: "#{App.Config.server}/api/login"
      data: JSON.stringify data
      beforeSend: (xhr) ->
        xhr.setRequestHeader('X-Timezone', moment().format('Z'))
    .done (data) =>
      @createSession data.data
      @trigger "login:successfull"
    .fail (resp) =>
      @trigger "login:failed", resp.responseText

  logout: ->
    $.ajax "#{App.Config.server}/api/logout",
      success: =>
        @destroySession()

  eventBroker: (event) ->
    if event.originalEvent.key is 'currentUser'
      location.reload()

  startListenUserLocalEvents: ->
    $(window).unbind 'storage', @eventBroker
    $(window).bind 'storage', @eventBroker

  _catchCometMessage: (e) =>
    data = $.parseJSON e.data

    @trigger "message", data

    type = data.data.type

    @trigger "message:#{type}", data.data
    @trigger "message:#{type}:#{data.data.module}", data.data

    # TODO: в случае если открыто больше одной вкладок, будет столько же раз происходить
    # загрузка экспорта
    window.location = "#{App.Config.server}#{uri}" if uri = data?.data?.data?.uri

  startListenUserChannel: ->
    @pushstream = new PushStream
      host                : App.Config.server.replace /(http:\/\/|https:\/\/)/, ""
      modes               : "websocket|eventsource|stream"
      useSSL              : useSSL
      urlPrefixWebsocket  : "/api/notify/listen"

    @pushstream.onstatuschange = (e) =>
      if e is PushStream.OPEN
        @pushstream.wrapper.connection.onmessage = @_catchCometMessage

    @pushstream.removeAllChannels()
    @pushstream.addChannel @.get('CHANNEL_NAME')
    @pushstream.connect()

    # socket broadcast stream
    broadcastStream = @broadcastStream = new WebSocket(broadcastSocket)
    broadcastStream.onmessage = (msg) =>
      try
        return if not data = JSON.parse(msg.data)
        @onMessageFromBroadcastSocket(data.data)

  stopListenUserChannel: ->
    if @pushstream then @pushstream.disconnect()
    @broadcastStream?.close()

  destroySession: ->
    $.ajaxSetup
      statusCode: null

    @stopListenUserChannel()

    App.vent.trigger "user:destroy"
    @trigger 'user:destroy'

  isAvailableAbility: (ability) ->
    product = App.Setting.get("product") or ""

    for productAbility of productAbilityList

      if (ability.match("^#{productAbility}") and not _.contains(productAbilityList[productAbility], product))
        return false

    return true

  createSession: (data) ->
    # создаем набор абилок пользователя на основе привилегий
    res = []

    if App.Config.extraPrivileges
      for priviledge in App.Config.extraPrivileges.split ","
        data.privileges.push
          ROLE_ID: 1
          PRIVILEGE_CODE: priviledge

    # фильтруем способности по лейблу продукта
    for priviledge in data.privileges

      userAbility = priviledge.PRIVILEGE_CODE
      res.push(userAbility) if @isAvailableAbility(userAbility)

    data.abilities = res

    @set data

    # начинаем слушать пользовательский канал
    @startListenUserChannel()
    @startListenUserLocalEvents()

    if App.Config.server is ''
      localStorage.setItem 'currentUser', App.Helpers.getCookieByName('PHPSESSID')

    $.ajaxSetup
      statusCode:
        401: =>
          PNotify.removeAll()
          @destroySession()
        403: =>
          PNotify.removeAll()
          @destroySession()

    @trigger 'user:create'

  isNotRole: ->
    not @can arguments...

  can: (o) ->
    abilities = @get 'abilities'

    # key: 'protected:show'
    return true if o.key and _.indexOf(abilities, o.key) isnt -1

    search = (key) -> if key.search(pattern) isnt -1 then true else false

    # module: 'protected'
    # or url: 'settings/access'
    if pattern = o.url or o.module
      regexp  = if o.action then "^#{pattern}:#{o.action}$" else "^#{pattern}[/:]"
      pattern = new RegExp regexp

    # type: 'document'
    pattern = new RegExp "[:/]#{o.type}:#{o.action or 'show'}$" if o.type
    return Boolean _.find(abilities, search) if pattern
    false

  parse: (response) ->
    response = response.data ? response
    response.roles = new Roles.Collection(response.roles)
    response.visibilityareas = new Scopes.Collection(response.visibilityareas)

    delete response.PASSWORD
    response

  onMessageFromBroadcastSocket: (msg) ->
    if msg.message is "wait_other"
      if App.Session.user.isUpdateOwner()
        App.Notifier.showSuccess
          title: App.t("settings.update.notify__attention")
          text: App.t("settings.update.notify__update_owner_wait_other")
      else
        App.Notifier.showSuccess
          title: App.t("settings.update.notify__attention")
          text: App.t("settings.update.notify__update_wait_other")
          hide: false

        setTimeout(@logout.bind(@), 30000)

  isUpdateOwner: ->
    @_updateOwner

  setUpdateOwner: (value) ->
    if value isnt undefined
      @_updateOwner = value

  isPredefined: ->
    parseInt(@get('USER_TYPE'), 10) in @predefinedUserTypes

  isEditable: ->
    parseInt(@get('EDITABLE'), 10) is 1

  isActive: ->
    parseInt(@get('STATUS'), 10) is 1


exports.Collection = class Users extends App.Common.BackbonePagination

  url: "#{App.Config.server}/api/user"

  model: exports.Model

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/user?start=#{@currentPage * @perPage}&limit=#{@perPage}"

      if @filter
        url += "&" + $.param(@filter)

      if @sortRule
        url += "&" + $.param(@sortRule)

      return url

    dataType: "json"
