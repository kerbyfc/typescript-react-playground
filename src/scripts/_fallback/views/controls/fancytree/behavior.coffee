"use strict"

module.exports = class FancyTreeBehavior extends Marionette.Behavior

  ###*
   * Default options, that should be merged with
   * constructor options argument, and then mixed to
   * fancytree view
   * @type {Object}
  ###
  defaults: {}

  ###*
   * Fancytree plugin dependencies dnd/filter/etc...
   * @type {Array}
  ###
  extensions: []

  ###
   * Methods to be defined in view
  ###
  @methods = {}

  ###*
   * Merge passed and default options, create handlers
   * @param  {FancyTree} view
   * @param  {Object} options = {}
  ###
  constructor: (options = {}, @view) ->
    @options = _.merge {}, _.result(@, 'defaults'), options

    # register fancytree extensions
    @view.options.extensions = _.union (@view.options.extensions or []), @extensions

    # define view methods
    for method, reqres of @methods
      reqres = _.kebabCase(method).replace /\-/g, ":"
      unless @[method]
        throw new Error "#{@constructor.name}.#{method} implementation missed"
      @view._defineMethod _.camelCase(method), reqres, @[method], @

    super
