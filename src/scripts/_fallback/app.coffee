"use strict"

Config = require "settings/config"
require "i18next"
require "mousetrap"
require "select2"
require "select2_locale_ru"
ZeroClipboard = require "zeroclipboard"
co = require "co"

App = new Marionette.Application
App.Behaviors = {}
App.Objects = {}
App.Layouts = {}
App.Common = {}
App.Helpers = {}
App.Config = Config
App.Models = {}
App.Views = {}
App.Controllers = {}

App.Radio = {}
App.Radio.plugins = Backbone.Wreqr.radio.channel "plugins"

App.Routes = {}
App.Timers = {}
App.EventsConditionsManager = {}
App.EventsConditionsManager.Events = {}
App.EventsConditionsManager.Dashboards = {}

App.t = (key, options = {}) ->
  if options is true
    $.i18n.t key, returnObjectTrees: true
  else
    $.i18n.t key, options

_setFavicon = (product) ->
  head = document.head or document.getElementsByTagName('head')[0]

  link = document.createElement('link')
  oldLink = document.getElementById('dynamic-favicon')

  link.id   = 'dynamic-favicon'
  link.type = 'image/x-icon'
  link.rel  = 'shortcut icon'
  link.href = "#{App.Config.server}/favicon_#{product}.ico"

  if oldLink
    head.removeChild(oldLink)

  head.appendChild(link)

App.Setting = new class extends Backbone.Model
  urlRoot : "#{App.Config.server}/api/setting"
  parse : (data) -> data.data

# Debug.js initialization
window.Debug = require "debug"
window.debug = Debug('app:')
wildcard     = localStorage.getItem("debug") or "*"
debugHint    = "Debug messages are currently filtered by '#{wildcard}' wildcard"
apiHint      = "∆ Use Debug.enable to change filter"
apiExample   = "Debug.enable('*my:filter*,app:*'); location.reload()"
hintStyle    = "color:green;font-weight:bold;font-size:150%;"

# log information about debug filters
console?.log? "%c#{debugHint}", hintStyle
console?.log? "%c#{apiHint}: #{apiExample}", "color:gray"

# apply filtering
Debug.enable wildcard

co ->
  data = yield [
    App.Setting.fetch wait: true

    new Promise (resolve) ->
      $.ajax "#{App.Config.server}/api/user/check"
      .always (some..., resp) -> resolve resp.responseJSON?.data
  ]

  yield [
    # Инициализируем локализацию
    $.i18n.init
      resGetPath  : App.Config.resourcePath
      load        : 'current'
      fallbackLng : 'ru'
      cookieName  : 'language'
  ]

  data
.then ([settings, userSession]) ->
  $.i18n.addPostProcessor "entry", (value, key, o) ->
    entry = o.postProcess
    delete o.postProcess
    if o.context and o.context is "error"
      namespace = "form.error"
    else namespace = "global"
    o.defaultValue = App.t "#{namespace}.#{key}", o
    context = if o.context then "_#{o.context}" else ''
    App.t "entry.#{o.entry}.#{key}#{context}", o

  # Добавляем основные регионы странички
  App.addRegions
    main: ".layout"

  App.addInitializer ->
    ZeroClipboard.config
      swfPath: "scripts/ZeroClipboard.swf"

    if $.i18n.lng() is 'ru'
      $.extend($.fn.select2.defaults, $.fn.select2.locales['ru'])
    else
      $.extend($.fn.select2.defaults, $.fn.select2.locales['en'])

    product = App.Setting.get 'product'

    # Определяем основной тип продукта - TM/PDP
    if product.indexOf('tm') is 0
      product_type = App.t 'global.tm'
      product = product.substring 2
    else if product.indexOf('pdp') is 0
      product_type = App.t 'global.pdp'
      product = product.substring 3

    # Определяем подтип продукта - Enterprise/Standard
    if product.indexOf('e') isnt -1
      product_subtype = App.t 'global.product_types.e'

    if product.indexOf('s') isnt -1
      product_subtype = App.t 'global.product_types.s'

    # Определяем установка в Appliance или нет
    installation_type = ''
    if product.indexOf('a') isnt -1
      installation_type = App.t 'global.product_types.a'

    document.title = "#{product_type} #{product_subtype} #{installation_type}"
    _setFavicon(App.Setting.get 'product')

    #Стартуем сессию
    App.vent.trigger "session:start", userSession

window.App = App
module.exports = App
