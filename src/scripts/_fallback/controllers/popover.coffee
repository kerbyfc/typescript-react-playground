"use strict"

entry   = require "common/entry.coffee"
style   = require "common/style.coffee"
helpers = require "common/helpers.coffee"

App.module "Application.Popover",
  startWithParent: true

  define: (Module, App) ->

    timeout = 1200

    getContainer = ($el) ->
      container = $el.closest style.selector.container.join ','
      container.get 0

    getPlacement = (popover, target) ->
      if $(target).offset().top > $(window).height()/2
        "top"
      else
        "bottom"

    getViewportAdjustedDelta = (placement, pos, actualWidth, actualHeight) ->
      delta =
        top  : 0
        left : 0

      return delta unless @$viewport
      viewportPadding    = @options.viewport and @options.viewport.padding or 0
      viewportDimensions = @getPosition(@$viewport)
      if /right|left/.test(placement)
        topEdgeOffset  = pos.top - viewportPadding - viewportDimensions.scroll
        bottomEdgeOffset = pos.top + viewportPadding - viewportDimensions.scroll + actualHeight

        if topEdgeOffset < viewportDimensions.top # top overflow
          delta.top = viewportDimensions.top - topEdgeOffset
        else if bottomEdgeOffset > viewportDimensions.top + viewportDimensions.height # bottom overflow
          delta.top = viewportDimensions.top + viewportDimensions.height - bottomEdgeOffset
      else
        leftEdgeOffset  = pos.left - viewportPadding
        rightEdgeOffset = pos.left + viewportPadding + actualWidth

        if leftEdgeOffset < viewportDimensions.left # left overflow
          delta.left = viewportDimensions.left - leftEdgeOffset
        # В оригинальном бутстрапе 3.2 не корректно работает, если контейнер имеет offset left > 0
        # viewportDimensions.width - фикс
        else if rightEdgeOffset > viewportDimensions.width + viewportDimensions.left # right overflow
          delta.left = viewportDimensions.left + viewportDimensions.width - rightEdgeOffset
      delta

    onMouseLeave = (e) ->
      $el      = $ e.currentTarget
      popover  = $el.data "bs.popover"
      $tip     = popover?.$tip
      interval = $el.data 'interval'

      isHover = $el.data 'isHover'
      return unless isHover
      $el.data "isHover", false

      window.clearInterval interval
      return unless $tip

      timer = _.delay ->
        $el.popover "destroy"
      , 500

      $tip.one 'mouseenter.clearPopover', (e) ->
        window.clearTimeout timer

      $tip.one 'mouseleave.clearPopover', (e) ->
        $el.popover "destroy"

    setPopover = ($el, options, shownBsPopover) ->

      container = getContainer $el

      margin  = $(container).outerWidth() - $(container).width()
      margin  = margin / 2
      padding = if margin < 20 then margin else 20

      $el
      .popover "destroy"
      .popover _.extend
        html      : true
        trigger   : "manual"
        placement : getPlacement
        viewport  :
          selector : container
          padding  : padding
        container : container
        title    : ->
          data = $(@).data()
          if data.popoverTitle
            if _.isFunction data.popoverTitle
              data.popoverTitle.apply @, arguments
            else
              data.popoverTitle
          else ""
        content  : ->
          data = $(@).data()
          if data.popoverContent
            if _.isFunction data.popoverContent
              data.popoverContent.apply @, arguments
            else
              data.popoverContent
          else
            data.content or $(@).attr('data-original-title') or ''

      , options

      $el.data 'bs.popover'
      .getViewportAdjustedDelta = getViewportAdjustedDelta

      $el.popover "show"

      $tip = $el.data('bs.popover').$tip

      interval = window.setInterval ->
        if not $tip or not _.size($tip.parent())
          window.clearInterval interval

        if not $el or not _.size($el.parent())
          $tip?.remove()
          window.clearInterval interval
      , timeout

      $el.data 'interval', interval

    class Controller extends Marionette.Controller

      initialize: ->
        selectors     = style.selector.popover
        selector      = "#{selectors.entry},#{selectors.default},#{selectors.title}"
        selectorSlick = selectors.slick

        $ 'body'
        .on "focus.popover", selectorSlick, (e) ->
          $el  = $ e.currentTarget
          data = $el.data()

          setPopover $el,
            template : Marionette.Renderer.render data.popoverTemplate or 'controls/popover_error'

        .on "blur.popover", selectorSlick, (e) ->
          $ e.currentTarget
          .popover "destroy"

        .on "mouseenter.popover", selector, (e) ->
          $el   = $ e.currentTarget
          data  = $el.data()
          $el.data "isHover", true

          return if $el.data('isDelay')
          $el.data "isDelay", true

          type = data.entryType
          id   = data.entryId
          $el.one 'mouseleave.clearPopover', onMouseLeave

          if type and id
            return _.delay ->
              $el.data "isDelay", false
              return unless $el.data('isHover')
              entry.getPopoverModel type, id, (data, model) ->
                return if not $el.data('isHover') or not data or data.error

                setPopover $el,
                  template: Marionette.Renderer.render 'controls/popover', type: type

                  title: ->
                    model.t null, context: 'title'

                  content: ->
                    if data.isDeleted
                      return Marionette.Renderer.render "controls/popover/deleted"

                    if islock = model.islock(type: model.type)
                      defaultValue = model.t islock.key, context: 'error'
                      return model.t "#{islock.key}_show",
                        context      : 'error'
                        defaultValue : defaultValue

                    Marionette.Renderer.render "controls/popover/#{model.type}", data, model: model
            , timeout

          content = $el.attr "title"

          if content
            $el.data 'content', content
            $el.attr 'title', ''

          _.delay ->
            $el.data "isDelay", false
            return unless $el.data('isHover')

            setPopover $el,
              template : Marionette.Renderer.render data.popoverTemplate or 'controls/popover'
          , timeout

        .on "mouseleave.popover", selector, onMouseLeave

    # Initializers And Finalizers
    # ---------------------------
    Module.addInitializer ->
      App.Popover = new Controller

    Module.addFinalizer ->
      delete App.Popover
