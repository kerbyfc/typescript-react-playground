"use strict"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Search extends Marionette.Behavior

  defaults:
    container     : '[data-search]'
    minCountSearch: 0

  collectionEvents:
    "search:update" : "_update"
    "search:loading": "_setLoadingState"
    "search:clear"  : "_reset"
    "update"        : "_refreshResult"


  _update: (eventParams = {}, eventOptions = reset: true) ->
    collection = @view.collection
    searchQuery = @$input.val()

    if searchQuery is collection.searchQuery and _.isEmpty(eventParams)
      return

    collection.trigger('search:loading', true)

    _.extend collection,
      currentPage: collection.firstPage
      searchQuery: searchQuery
    ,
      eventParams

    options =
      success: ->
        collection.trigger('search:loading', false)

    _.extend options,
      eventOptions

    filter = collection.filter.filter
    nameAttribute = collection.model::nameAttribute

    if searchQuery
      searchQuery = "*#{searchQuery}" if searchQuery.charAt(0) isnt '*'
      searchQuery = searchQuery + '*' if searchQuery.charAt(searchQuery.length - 1) isnt '*'

      if _.isFunction collection.filter
        options.data = filter: {}
        options.data.filter[nameAttribute] = searchQuery
      else
        filter[nameAttribute] = searchQuery

    else
      if filter?[nameAttribute]
        delete filter[nameAttribute]

    collection.search options


  _setLoadingState: (state) ->
    $container = @$el.find @options.container
    attr = 'data-search-loading'
    if state
      $container.attr(attr, '')
    else
      $container.removeAttr(attr)


  _reset: ->
    @$input.val('')
    @view.collection.searchQuery = ''


  _refreshResult: ->
    collection = @view.collection
    $container = @$el.find @options.container

    show = false
    count = collection.getTotalLength()

    if count and (count > @options.minCountSearch or collection.length > @options.minCountSearch)
      show = true
    collection.trigger('search:show', show)

    if show
      return $container.show()

    if @$input.val()
      return

    $container.hide()


  onRender: ->
    @$input = @$el
      .find(@options.container)
      .find('input')

    @$input.on("keyup", @_update.bind(@))
