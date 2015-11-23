"use strict"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Paginator extends Marionette.Behavior

  defaults:
    container: "[data-paginator]"
    button: "[data-paginator-button]"
    size: "[data-paginator-size]"


  collectionEvents:
    "add remove": "_place"
    "sync reset": "_update"


  get: ->
    totalPages      : @totalPages
    currentPage     : @currentPage
    perPage         : @perPage
    pageSizes       : @pageSizes
    showPageSize    : true

    pages: =>
      if @currentPage < @pagesInRange
        start = 1
      else
        start = Math.floor(@currentPage / @pagesInRange) * @pagesInRange + 1

      if @totalPages < @pagesInRange
        end = @totalPages
      else
        end = start + @pagesInRange - 1
        end = @totalPages if @totalPages < end

      [ start..end ]

    isActive: (count) =>
      return true if count is @currentPage + 1

    isDisabled: (type) =>
      switch type
        when 'first', 'prev'
          return true if @length is 0 or @currentPage is 0
        when 'next', 'last'
          return true if @length is 0 or @currentPage is @totalPages - 1
        when 'prevRange'
          return true if @currentPage >= @pagesInRange
        when 'nextRange'
          if @totalPages > @pagesInRange and
          @currentPage < Math.floor( @totalPages / @pagesInRange ) * @pagesInRange
            return true
        else
          return true if +type is @currentPage + 1
      false


  onRender: ->
    @$container = @$el.find @options.container
    collection = @view.collection

    @listenTo App, "resize", @_place

    @$container
      .on "change", @options.size, (e) ->
        if _.isFunction(collection.search)
          collection.trigger 'search:update',
            perPage: +$(e.currentTarget).val()
        else
          if collection.length
            return collection.howManyPer +$(e.currentTarget).val()

      .on "click", @options.button, ->
        count = $(@).data('paginatorButton')
        reset = true

        switch count
          when "first"
            page = collection.firstPage
          when "last"
            page = collection.totalPages - 1
          when "prev"
            page = collection.currentPage - 1
          when "next"
            page = collection.currentPage + 1
          when "prevRange"
            page = collection.currentPage - Math.floor(collection.currentPage % collection.pagesInRange) - 1
            reset = false
          when "nextRange"
            page = Math.floor(collection.currentPage/collection.pagesInRange) * collection.pagesInRange + collection.pagesInRange
            reset = false
          else
            page = +count - 1

        if _.isFunction(collection.search)
          collection.trigger 'search:update',
            currentPage: page
          ,
            reset: reset
        else
          collection.goTo(page, reset: reset)


  _place: ->
    collection = @view.collection
    options = @view.grid.getOptions()
    rowHeight = options.rowHeight
    headerRowHeight = options.headerRowHeight

    position = 'auto'
    if collection.length
      d = headerRowHeight + collection.length * rowHeight
      height = @view.getContainer().parent().data('height')
      if d < height
        position = d - height

    @$container.css('top', position)


  _update: ->
    options = @get.apply(@view.collection)
    @$el.find(@options.container).html(Marionette.Renderer.render("controls/paginator", options))

    $(@options.size).select2(minimumResultsForSearch: 100)
    App.trigger("resize", "paginator", @)
    @_place()
