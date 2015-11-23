"use strict"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.LazyLoad extends Marionette.Behavior

  # *************
  #  PRIVATE
  # *************
  _on_scroll = ->
    scroll_el = @ui.lazy_load_container[0]
    scroll_px_yet = scroll_el.scrollTop
    need_scroll_px_for_callback =
      scroll_el.scrollHeight - scroll_el.offsetHeight - ( @options.scroll_k  or  150 )
    is_callback = scroll_px_yet > need_scroll_px_for_callback

    if is_callback
      if @view.collection.length < @view.collection.total_count
        @options.callback.call @view
      else
        @options.cancel_callback.call @view


  # ****************
  #  MARIONETTE
  # ****************
  ui :
    lazy_load_container : "[data-lazy-load]"


  # ***********************
  #  MARIONETTE-EVENTS
  # ***********************
  onShow : ->
    @ui.lazy_load_container.on "scroll",
      _.throttle _on_scroll.bind( @ ),
        @options.throttle_delay  or  333
