"use strict"

App.Views.Controls ?= {}

class App.Views.Controls.Paginator extends Marionette.ItemView

  template: "controls/paginator"

  className: "paginator"

  collectionEvents:
    'sync': -> @render()

  templateHelpers: ->
    c = @collection

    totalPages      : c.totalPages
    currentPage     : c.currentPage
    perPage         : c.perPage
    pageSizes       : c.pageSizes
    showPageSize    : @options.showPageSize

    pages: ->
      if c.currentPage < c.pagesInRange
        start = 1
      else
        start = Math.floor(c.currentPage / c.pagesInRange) * c.pagesInRange + 1

      if c.totalPages < c.pagesInRange
        end = c.totalPages
      else
        end = start + c.pagesInRange - 1
        end = c.totalPages if c.totalPages < end

      [ start..end ]

    isActive: (count) ->
      return true if count is c.currentPage + 1

    isDisabled: (type) ->
      switch type
        when 'first', 'prev'
          return true if c.length is 0 or c.currentPage is 0
        when 'next', 'last'
          return true if c.length is 0 or c.currentPage is c.totalPages - 1
        when 'prevRange'
          return true if c.currentPage >= c.pagesInRange
        when 'nextRange'
          if c.totalPages >= c.pagesInRange and
          c.currentPage < Math.floor( c.totalPages / c.pagesInRange ) * c.pagesInRange
            return true
        else
          return true if +type is c.currentPage + 1
      false

  events:
    "click  @ui.buttons" : "onClick"
    "change @ui.size"  : "onChange"

  ui:
    buttons : "[data-paginator-button]"
    size    : "[data-paginator-size]"

  onClick: (e) ->
    c = @collection
    switch count = $(e.currentTarget).data('paginator-button')
      when "first"
        c.goTo 0, reset: true
      when "last"
        c.goTo c.totalPages - 1, reset: true
      when "prev"
        c.prevPage reset: true
      when "next"
        c.nextPage reset: true
      when "prevRange"
        c.goTo c.currentPage - Math.floor(c.currentPage % c.pagesInRange) - 1
      when "nextRange"
        next = Math.floor(c.currentPage/c.pagesInRange) * c.pagesInRange + c.pagesInRange
        c.goTo next
      else
        c.goTo +count - 1, reset: true

  onChange: (e) ->
    @collection.howManyPer +$(e.currentTarget).val() if @collection.length

  onRender: ->
    @ui.size.select2 minimumResultsForSearch: 100
