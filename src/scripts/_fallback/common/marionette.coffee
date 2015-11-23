"use strict"

select2 = require "common/select2.coffee"
helpers = require "common/helpers.coffee"
ECT     = require "ect"
renderer  = ECT root: T # there must be the templates object

Marionette.TemplateCache.templateCaches = T

Marionette.Renderer.render = (templatePath, data, context) ->
  data = helpers.extend data, context

  renderer.render templatePath, data, context

App.Behaviors.Common ?= {}
Marionette.Behaviors.behaviorsLookup = App.Behaviors.Common

# ************
#  MODULE
# ************
Marionette.Module::islock = (o = {}) ->
  module = o.module
  module ?= @moduleName

  helpers.can arguments...

Marionette.Module::can = ->
  not @islock arguments...

orig_module_stop = Marionette.Module::stop
Marionette.Module::stop = ->
  # if we are not initialized, don't bother finalizing
  return  unless @_is-initialized

  orig_module_stop.call @

  @reqres.removeAllHandlers() # TODO: @reqres.off();
  @off()
  @stopListening()
  _.each @collections, (c) -> c.reset()
  @collections = []

  if @obj?
    for own key of @obj
      @obj[key].off?()
      @obj[key].stopListening?()
      @obj[key] = null


orig_module_start = Marionette.Module::start
Marionette.Module::start = (options) ->
  # Prevent re-starting a module that is already started
  return if @_is-initialized

  # TODO в перспективе выкосить
  # https://github.com/marionettejs/backbone.marionette/issues/452
  @reqres  ?= new Backbone.Wreqr.RequestResponse
  @request ?= @reqres.request
  @collections = []

  orig_module_start.call @, options


orig_module_definition = Marionette.Module::add-definition
Marionette.Module::addDefinition = (moduleDefinition, customArgs) ->
  @obj ?= {}
  @cls ?= {}

  orig_module_definition.apply @, arguments


class Marionette.Behavior extends Marionette.Behavior

  ###*
   * Create logger if isn't exist and
   * print message to console with debug.js
  ###
  log: helpers.createLogger "behavior", (key) ->
    "#{_.snakeCase @view.constructor.name}:#{key}"

class Marionette.Controller extends Marionette.Controller

  ###*
   * Create logger if isn't exist and
   * print message to console with debug.js
  ###
  log: helpers.createLogger "controller"

class Marionette.Region extends Marionette.Region

  # ************************
  #  MARIONETTE-REWRITE
  # ************************
  attachHtml : (view) ->
    if view.render_without_root
      @$el.replaceWith view.el
    else
      super

  ###*
   * Create logger if isn't exist and
   * print message to console with debug.js
  ###
  log: helpers.createLogger "region"

  show : (view, options) ->
    unless @_ensureElement()
      return
    @_ensureViewIsIntact view

    if view.render_without_root
      view.setElement @el

    super

# patch View destroy method
App.Helpers.injectCondition Marionette.View.prototype, "destroy", ->
  not _.isFunction(@shouldBeDestroyed) or
    @shouldBeDestroyed.apply(@, arguments) is true


serialize = ->
  # TODO: вынести в конфиги сифона

  # Проверяем есть ли зарегестрированные ридеры для нашего типа
  # и если есть - сохраняем обработчик
  if Backbone.Syphon.InputReaders.registeredTypes.textarea?
    previous_reader = Backbone.Syphon.InputReaders.registeredTypes.textarea

  # Регестрируем свой обработчик для textarea
  Backbone.Syphon.InputReaders.register 'textarea', (el) ->
    # Если это наш клиент с типом select2

    if $(el).data('form-type') is 'select2'
      val = el.val()

      if val
        val = _.map val.split(select2.outerSeparator), (item) ->
          d = item.split select2.innerSeparator

          TYPE : d[0]
          ID   : d[1]
          NAME : d[2]
      else val = null

      return val
    else
      return el.val()

  data = Backbone.Syphon.serialize @,
    exclude: _.result(@, 'exclude')
    keySplitter: (key) ->
      matches = key.match(/[^\[\]]+/g)

      matches

  # Разрегестрируем наш обработчик
  Backbone.Syphon.InputReaders.unregister 'textarea'
  # Возвращаем старый
  if previous_reader
    Backbone.Syphon.InputReaders.registeredTypes.textarea = previous_reader

  data

exclude = ['hour', 'minute']

for viewType in ['ItemView', 'LayoutView', 'CompositeView']
  Marionette[viewType]::getData = -> serialize.apply @, arguments...
  Marionette[viewType]::serialize = -> serialize.apply @, arguments...
  Marionette[viewType]::exclude = -> exclude

_.each [
  "CollectionView"
  "CompositeView"
  "LayoutView"
  "ItemView"
], (class_name) ->

  class Marionette[class_name] extends Marionette[class_name]

    # ***********************
    #  BACKBONE-REWRITE
    # ***********************

    # TODO заменить на _removeElement при Backbone > 1.1.2
    remove : ->
      if @render_without_root
        @$el.off()
        @$el.empty()
        @stopListening()
        @
      else
        super

    log: App.Helpers.createLogger _.snakeCase class_name

    # ************************
    #  MARIONETTE-REWRITE
    # ************************
    regionClass  : Marionette.Region

    ###*
     * To be able to use with browserify
     * @note From Marrionette documentation
     * @param  {Object} options - behaviour options
     * @param  {String} key - behavior key in behaviors object
     * @return {Marrionette.Behavior}
    ###
    getBehaviorClass: (options, key) ->
      options.behaviorClass or Marionette.Behaviors.behaviorsLookup[key]
