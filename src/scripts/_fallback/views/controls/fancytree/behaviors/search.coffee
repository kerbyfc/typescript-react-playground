"use strict"

FancyTreeBehavior = require "../behavior.coffee"

module.exports = class FancyTreeSearchBehavior extends FancyTreeBehavior

  methods: {
    "search"
    "resetSearchQuery"
    "getSearchQuery"
  }

  ###*
   * Default values for fancytree dnd extension
   * @type {Object}
  ###
  defaults:
    quicksearch : true
    container   : false
    input       : "[data-search] > input"
    template    : "controls/fancytree/search"
    value       : ""
    placeholder : ""
    autoApply   : true
    autoExpand  : true
    mode        : "hide"

  ###*
   * Options to mixin to fanctytree options
   * @type {Array}
  ###
  exportOptions: [
    "autoApply"
    "autoExpand"
    "mode"
    "quicksearch"
  ]

  ###*
   * Fancytree plugin dependencies
   * @type {Array}
  ###
  extensions: ['filter']

  initialize: ->
    unless @options.container
      throw new Error "Search extension needs `container` option"

    # mixin options to fancytree
    _.merge @view.options,
      filter: _.pick @options, @exportOptions...

    @listenTo @view, "show", @onViewRender

  onViewRender: =>
    @container = @view.$ @options.container
    @container.html Marionette.Renderer.render @options.template, @options

    @input = @container.find @options.input
    @input.on "keyup", @_search

  ###########################################################################
  # PRIVATE

  ###*
   * Clear or change filter
  ###
  _search: (e) =>
    if e.which is $.ui.keyCode.ESCAPE or
    not $.trim @input.val()
      @resetSearchQuery()
    else
      @search @input.val()

  ###########################################################################
  # INTERFACE

  ###*
   * Filter nodes with search query
   * @param  {String} query
  ###
  search: (query) =>
    if @query isnt query and @view.tree?
      @query = query
      @view.tree.filterNodes @query, @options
      @input.val query

  ###*
   * Clear search
  ###
  resetSearchQuery: ->
    @query = ""
    @view.tree.clearFilter()

  ###*
   * Get or set value
   * @param  {String} value - value to set
  ###
  getSearchQuery: ->
    @input.val value
