"use strict"

require "layouts/dialogs/confirm.coffee"

App.Helpers.checkBrowser = ->
  /chrome/i.test(navigator.userAgent) and navigator.userAgent.match(/chrome\/(\d+(\.\d+)?)/i)[1] > 38

App.Helpers.mergeDeep = (objects...) ->
  [first, second, tail...] = objects

  merged = _.merge first, second, (value1, value2) ->
    # concat arrays
    if _.isArray(value1) and _.isArray(value2)
      _.union(value1, value2)

    # merge objects
    else if _.isObject(value1) and _.isObject(value2)
      App.Helpers.mergeDeep(value1, value2)

  if tail.length
    _.merge [merged].concat(tail)...

  else
    merged

###*
 * Build object from array by chunking arguments or income array
 * @param {Array|...(Array|Any)} keyValuePairs
 * @return {Object} builded object
###
App.Helpers.toObject = (keyValuePairs...) ->
  switch
    # when ['key1', 'val1', 'a.b', 'val2']
    when _.isArray(_.first keyValuePairs) and keyValuePairs.length is 1
      App.Helpers.toObject _.first(keyValuePairs)...

    # when = ['key1, 'val1'], ['a.b', 'val2' ], ...
    when _.all(keyValuePairs, _.isArray) and _.all(keyValuePairs, (array) -> array.length is 2)
      App.Helpers.toObject _.flatten(keyValuePairs)...

    # when 'key1', 'val1', 'a.b', 'val2', ...
    else
      _.reduce _.chunk(keyValuePairs, 2), (acc, array) ->
        _.set acc, array[0], _.clone array[1]
        acc
      , {}

App.Helpers.cloneDeep = (object) ->
  dirty = false
  for own key, val of object
    if val instanceof Backbone.Model or val instanceof Backbone.Collection
      dirty = true
      break

  if dirty
    _.clone object
  else
    _.cloneDeep object

###*
 * Flatten tree structure to array of tree nodes
 * @param {Object|Array} tree - root node/nodes
 * @param {Object} options
 * @return {Array} tree nodes
###
App.Helpers.flattenTree = (tree, options = children: "children", nodes = [], depth = 1) ->
  # if node is passed
  if not _.isArray tree
    tree = [tree]

  for node in tree
    nodes.push node

    if children = _.get(node, options.children)
      App.Helpers.flattenTree children, options, nodes, depth+1

  if depth is 1
    nodes = _.uniq nodes

  nodes

###*
 * Create logger if isn't exist and
 * print message to console with debug.js
###
App.Helpers.createLogger = (type, keyModifier) ->
  (args...) ->
    # determine scope addition
    first = _.first args
    key = if first and _.isString(first) and first.match /^\:\w+/
      args.shift().slice 1
    else
      "common"

    # try to get logger by key
    logger = @loggers?[key]

    if not logger

      # extend scope with type
      # unless it isn't in class name
      scope = _.snakeCase @constructor.name
      if not scope.match ///#{type}$///i
        scope += "_#{type}"

      if key isnt "common"
        # first contains ":#{key}"
        scope += first

      # to be able to modify keys between
      # class instancies
      if _.isFunction keyModifier
        scope = keyModifier.call @, scope

      loggers = @constructor::loggers ?= {}

      # create and register logger by key
      logger = loggers[key] = new Debug scope

    logger args...

###*
 * Lodash equal with some type casting
 * @param {Any} value1
 * @param {Any} value2
 * @result {Boolean} equality
###
App.Helpers.isEqual = (values...) ->
  for value, i in values
    if String(value).match /^\d+$/
      values[i] = parseInt value, 10
  _.isEqual values...

App.Helpers.getCookieByName = (name) ->
  nameEQ = name + "="

  for cookie in document.cookie.split(';')
    while (cookie.charAt(0) is ' ')
      cookie = cookie.substring(1, cookie.length)
    if (cookie.indexOf(nameEQ) is 0)
      return cookie.substring(nameEQ.length, cookie.length)

  return null

App.Helpers.getPredefinedLocalizedValue = (value, locale_path) ->
  if not value then return value

  locale = App.t(locale_path, { returnObjectTrees: true })

  if value.charAt(0) in ['_', '<'] and value.charAt(value.length - 1) in ['_', '>']
    if locale[value]
      locale[value]
    else
      _.escape value
  else
    _.escape value

# Возвращает единицу измерения с правильным окончанием
#
# @param {Number} num    Число
# @param {Object} cases    Варианты слова {nom: 'час', gen: 'часа', plu: 'часов'}
# @return {String}
App.Helpers.pluralize = (num, cases) ->
  num = Math.abs(num)

  word = ''

  if num.toString().indexOf('.') > -1
    word = cases.gen
  else
    word = (
      if num % 10 is 1 and num % 100 isnt 11
        cases.nom
      else
        if num % 10 >= 2 and num % 10 <= 4 and (num % 100 < 10 or num % 100 >= 20)
          cases.gen
        else
          cases.plu
    )

  return word

App.Helpers.getBytesWithUnit = ( bytes ) ->
  if isNaN( bytes ) then return

  units = [ ' bytes', ' kB', ' MB', ' GB', ' TB', ' PB', ' EB', ' ZB', ' YB' ]
  amountOf2s = Math.floor( Math.log( +bytes )/Math.log(2) )

  if amountOf2s < 1
    amountOf2s = 0

  i = Math.floor( amountOf2s / 10 )
  bytes = +bytes / Math.pow( 2, 10*i )

  if bytes.toString().length > bytes.toFixed(2).toString().length
    bytes = bytes.toFixed(2)


  return bytes + units[i]

###*
 * Generate name of copyed model.
 *
 * @example copy name generation for "Report"
 *   App.Helpers.generateCopyName("Report")   is "Report Copy 1"
 *
 * @example copy name generation for "Report" in case there is a report named "Report Copy 1"
 *   App.Helpers.generateCopyName("Report")   is "Report Copy 2"
 *   App.Helpers.generateCopyName("Report Copy 1") is "Report Copy 2"
 *
 * @param  {String} name - current name
 * @param  {Function} find - filter to find unique names collision
 * @return {String} new name
###
App.Helpers.generateCopyName = (name, find) ->
  ln = _.capitalize App.t('global.copied')

  # remove "copy i" from display name if it exists
  name = "#{name.replace(///\s*#{ln}\s\d$///i, '')} #{ln}"

  App.Helpers.resolveUniqueName name, find

App.Helpers.resolveUniqueName = (name, findFn) ->
  i = 1
  _name = name
  while findFn _name
    _name = "#{name} #{i++}"

  _name

# Creates and returns a blob from a data URL (either base64 encoded or not).
#
# @param {string} dataURL The data URL to convert.
# @return {Blob} A blob representing the array buffer data.
App.Helpers.data_url_to_blob = (dataURL) ->
  BASE64_MARKER = ';base64,'
  if dataURL.indexOf(BASE64_MARKER) is -1
    parts = dataURL.split(',')
    contentType = parts[0].split(':')[1]
    raw = parts[1]
    return new Blob([raw], {type: contentType})

  parts = dataURL.split(BASE64_MARKER)
  contentType = parts[0].split(':')[1]
  raw = window.atob(parts[1])
  uInt8Array = new Uint8Array(raw.length)

  for value, key in raw
    uInt8Array[key] = raw.charCodeAt(key)

  return new Blob([uInt8Array], {type: contentType})

App.Helpers.camelCase = (string, firstUp = false) ->
  string = _.camelCase(string)
  if firstUp
    string = _.capitalize(string)
  string

App.Helpers.getCountries = (country) ->
  countries = App.t "country", returnObjectTrees: true
  if country then countries[country] else countries

App.Helpers.getLanguages = (language) ->
  lang = App.t "language", returnObjectTrees: true
  if language then lang[language] else lang

App.Helpers.patterns =
  skype           : /^[a-zA-Z][a-zA-Z0-9\.,:\-_]{5,31}$/
  email           : /// ^ (
                  ([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)
                  | (\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])
                  | (([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,})
                  ) $///
  phone           : /^[0-9\-\+. ,_()]{3,25}$/
  mobile          : /^[0-9\-\+. ,_()]{3,25}$/
  icq             : /^[-0-9]{5,12}$/
  url             : /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
  url_with_masks  : /^(https?:\/\/)?([\da-z\%.*-]+)\.*([a-z\.]{2,6})([\/\w \%.*-]*)*\/?$/
  domain          : /^(xn--)?([a-z0-9]+([-:\.][a-z0-9]+)*)+$/
  ip              : /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
  dns             : /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/
  lotus           : /^(?!\+).+/
  netmask         : /^((255|254|252|248|240|224|192|128|0+)\.){3}(255|254|252|248|240|224|192|128|0+)$/

App.Helpers.isValid = (type, data) ->
  pattern = App.Helpers.patterns[type]
  return pattern.test data if pattern
  true

App.Helpers.getProductType = ->
  App.Setting.get 'product'

App.Helpers.getCurrentModule = ->
  App.currentModule

App.Helpers.getCurrentModuleName = ->
  App.currentModule?.moduleName

App.Helpers.can = ->
  not App.Helpers.islock arguments...

# TODO: вынести в модель LicenseManager
App.Helpers.license =
  "term"        : 'classifier'
  "fingerprint" : 'stamper'
  "text_object" : 'researcher'
  "form"        : 'formanalysis'
  "stamp"       : 'stamp_detector'
  "graphic"     : 'graphic'
  "table"       : 'tableanalysis'

  "analysis/term"        : 'classifier'
  "analysis/fingerprint" : 'stamper'
  "analysis/text_object" : 'researcher'
  "analysis/form"        : 'formanalysis'
  "analysis/stamp"       : 'stamp_detector'
  "analysis/graphic"     : 'graphic'
  "analysis/table"       : 'tableanalysis'

App.Helpers.isNotLicensed = (o) ->
  # TODO: вынести в модель LicenseManager
  license  = App.Helpers.license

  err =
    key     : 'not_licensed'
    state   : 2
    message : App.t 'form.error.not_licensed'
    mode    : 'hide'

  key = o.module or o.url

  if key and key is 'crawler'
    return err unless App.LicenseManager.hasInterceptFeature('crawler', 'tm')

  if key and key is 'analysis'
    licensed = _.find _.values(license), (item) ->
      return false unless App.LicenseManager.hasTechnologyFeature item
      true
    return err unless licensed

  key = o.type or o.url
  return err if key and license[key] and not App.LicenseManager.hasTechnologyFeature(license[key])

  false

App.Helpers.isNotRole = ->
  # TODO: вынести в модель current user
  user = App.Session.currentUser()

  isNotRole = user.isNotRole arguments...
  if isNotRole
    key     : 'not_role'
    state   : 2
    message : App.t 'form.error.not_role'
    mode    : 'disabled'
  else
    false

App.Helpers.isNotSupported = (o) ->
  # TODO: вынести в модель app setting
  # Настройка сетевых параметров Только TME/TMS/PDPE/PDPS Appliance
  # Обновление системы через веб-интерфейс Только TME/TMS Appliance

  product = App.Helpers.getProductType()

  type = o.type or o.module or o.url or ""

  # Если это не Appliance
  if product.indexOf('a') is -1
    if type in [ 'network', 'settings/network', 'update', 'settings/update' ]
      return {
        key: 'not_support'
        state: 2
        message: App.t 'form.error.not_support'
        mode: 'hide'
      }

  # Если это pdp
  if product.indexOf('pdp') isnt -1
    if type in ['category', 'stamp', 'term', 'placement', 'crawler', 'file', 'lists/file', 'analysis/stamp', 'analysis/term']
      return {
        key: 'not_support'
        state: 2
        message: App.t 'form.error.not_support'
        mode: 'hide'
      }

  return false

App.Helpers.isLocked = (options) ->
  type = options.type or options.module
  # TODO: вынести в модель session
  return false if type not in [
      'analysis'
      'protected'
      'term'
      'category'
      'group_text_object'
      'text_object'
      'group_fingerprint'
      'fingerprint'
      'group_form'
      'form'
      'group_stamp'
      'stamp'
      'group_table'
      'table'
      'document'
      'catalog'
      'policy_object'
      'policy_person'
      'group'
      'person'
      'workstation'
      'tag'
      'status'
      'perimeter'
      'resource'
  ]
  return false unless type
  return false unless App.Configuration.isLocked()

  key     : 'locked'
  state   : 2
  message : App.t "form.error.locked"
  mode    : 'disabled'

# TODO: вынести в common/backbone
App.Helpers.mapRoleAction =
  create     : 'edit'
  edit       : 'edit'
  update     : 'edit'
  add        : 'edit'
  activate   : 'edit'
  deactivate : 'edit'
  move       : 'edit'
  delete     : 'delete'
  remove     : 'delete'
  show       : 'show'
  import     : 'export'

App.Helpers.islock = (options = {}) ->
  # return false
  options.action = App.Helpers.mapRoleAction[options.action] or options.action if options.action

  # DEPRECATED: выпилить когда контроллер файлов будет перенесен в списки
  options.url = "lists/file" if options.url and options.url is 'file'
  options.url = 'lists/file' if options.module is 'file'

  err = App.Helpers.isNotSupported arguments...
  err = App.Helpers.isNotLicensed arguments... unless err
  err = App.Helpers.isLocked options if not err and options.action and options.action isnt 'show'
  err = App.Helpers.isNotRole arguments... unless err
  return err if err
  false

App.Helpers.extend = (data, context) ->
  data = _.extend
    style   : App.Style
    helpers : App.Helpers
    entry   : App.entry
    t       : App.t
    extend  : App.Helpers.extend
  , data

  return data unless context

  data.contextType = context.type

  if model = context.model
    data.type  ?= model.type
    data.name   = model.getName() if model.getName and not data.name
    data.id     = model.id
    data.can    ?= _.bind model.can, model if model.can
    data.islock ?= _.bind model.islock, model if model.islock
  else if collection = context.collection
    data.can    ?= _.bind collection.can, collection if collection.can
    data.islock ?= _.bind collection.islock, collection if collection.islock
  else
    data.can    ?= App.Helpers.can
    data.islock ?= App.Helpers.islock
  data

App.Helpers.reduceString = (str) ->
  return "" unless str
  str   = str.replace /\s+/g, ' '
  words = str.split " "
  if words.length is 1
    if words[0].length > 13
      return str.replace(/(.{10}).*(.{5})/, '$1...$2')
    else
      return str

  if words.length is 2
    if words[0].length < 10 and words[1].length < 5
      return str
    if words[0].length > 13 and words[1].length < 5
      return words[0].replace(/(.{10}).*/, '$1...') + ' ' + words[1]
    if words[0].length < 10 and words[1].length > 8
      return words[0] + ' ' + words[1].replace(/.*(.{5})/, '...$1')
    if words[0].length > 10 and words[1].length > 5
      return words[0].replace(/(.{10}).*/, '$1...') + ' ' + words[1].replace(/.*(.{5})/, '...$1')

  if words.length > 2
    if str.length < 17
      return str
    if ( words[0].length + words[1].length ) < 10
      w1 = words[0] + ' ' + words[1]
    else if words[0].length < 10
      w1 = words[0] + ' ' + words[1].replace(new RegExp('(.{'+(9 - words[0].length)+'}).*'), '$1')
    else
      w1 = words[0].replace(/(.{10}).*/, '$1')

    if words[words.length - 1].length > 5
      w2 = words[words.length - 1].replace(/.*(.{5})/, '$1')
    else
      w2 = words[words.length - 1]

    return w1 + ' ... ' + w2
  str

App.Helpers.reduceLongWord = (str) ->
  str = str.replace(/\s+/g, ' ')
  words = str.split " "
  words = _.map words, (word) ->
    if word.length > 20
      word = word.replace /(.{10}).*(.{5})/, '$1...$2'
    word
  words.join " "

# Создание подмножества объекта на основе карты ключей
# Пример:
#
# Источник:
# {
#   a: {
#   b: {
#     c: 1,
#     d: 2
#   },
#   k : [1, 2]
#   }
# }
#
# Карта:
# ["a.b.c", "a.k"]
#
# Результат:
# {
#   a: {
#   b: {
#     c: 1
#   },
#   k : [1, 2]
#   }
# }
App.Helpers.recursive_pick = (source, pick_arr) ->
  dest = {}

  for ns in pick_arr
    parts     = ns.split(".")
    stop_index    = parts.length - 1
    source_intermed = source
    dest_intermed = dest

    for val, key in parts
      source_intermed = source_intermed[val]

      if key is stop_index
        dest_intermed[val] = _.cloneDeep(source_intermed)
        break

      if typeof dest_intermed[val] is "undefined"
        dest_intermed[val] = {}

      dest_intermed = dest_intermed[val]

  dest

App.Helpers.trim = (str = '', n) ->
  if str.length > n then str.substr(0, n-1) + '&hellip;' else str


App.Helpers.guid = ->
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = (if c is "x" then r else (r & 0x3 | 0x8))
    v.toString 16


App.Helpers.sort_object_by_alphabet = (obj) ->
  new_obj = {}
  keys =
    _.keys obj
    .sort()

  for key in keys
    new_obj[key] = obj[key]

  new_obj


App.Helpers.virtual_class = (classes...) ->
  classes.reduceRight (Parent, Child) ->
    class ChildProjection extends Parent
      constructor: ->
        # Подменить Child.__super__ на стек вызова оригинального `constructor`
        child_super = Child.__super__
        Child.__super__ = ChildProjection.__super__
        Child.apply @, arguments
        Child.__super__ = child_super

        # Если Child.__super__ не существует, вызвать родительский `constructor`
        unless child_super?
          super

    # Замешать прототипные свойства, кроме `constructor`
    for own key  of Child::
      if Child::[key] isnt Child
        ChildProjection::[key] = Child::[key]

    # Замешать статические свойства, кроме `__super__`
    for own key  of Child
      if Child[key] isnt Object.getPrototypeOf(Child::)
        ChildProjection[key] = Child[key]

    ChildProjection


App.Helpers.html_trim = (html_str) ->
  html_str
  # remove newline / carriage return
  .replace /\n/g, ""
  # remove whitespace (space and tabs) before tags
  .replace /[\t ]+\</g, "<"
  # remove whitespace between tags
  .replace /\>[\t ]+\</g, "><"
  # remove whitespace after tags
  .replace /\>[\t ]+$/g, ">"


App.Helpers.show_datetime = (datetime, options = {}) ->
  options.input_mask ?= ""
  options.output_mask ?= "L LT"
  options.transformators ?= []
  options.is_utc ?= true

  moment_exec = if options.is_utc then moment.utc else moment

  _.reduce options.transformators, (accum, transfer) ->
    accum[transfer.name] transfer.args...
  ,
    moment_exec datetime, options.input_mask
  .local()
  .format options.output_mask

###*
 * Show confrimation dialog with options
 * @param  {Object} options - view options
 * @return {Marionette.LayoutView} view
###
App.Helpers.confirm = (options) ->
  view = new App.Layouts.ConfirmDialog options
  App.modal2.show view
  view

###*
 * Transition events
 * @type {String}
###
_transitionEnd = "transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd"

###*
 * Call callback once after transition ends
 * @param  {jQuery} el
 * @param  {Function} callback
###
App.Helpers.onTransition = (el, callback) ->
  el
    .off _transitionEnd
    .one _transitionEnd, callback

###*
 * Make method of some class(scope) to be executed by
 * passed condition
 * @param  {Object} scope - any object
 * @param  {String} method - method name
 * @param  {Function} condition
###
App.Helpers.injectCondition = (scope, method, condition) ->
  _bak = scope[method]
  scope[method] = ->
    return false if condition.apply(@, arguments) is false
    _bak.apply @, arguments

module.exports = App.Helpers
