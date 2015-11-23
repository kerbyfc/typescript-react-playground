"use strict"

module.exports = class CollapseBehavior extends Marionette.Behavior

  defaults:
    container: '[data-collapse-container]'
    item: '[data-collapse-item]'
    btnTemplate: 'controls/collapse/btn'
    btnClass: 'button _grey _small'

  events:
    'click button[data-action=collapse]': '_toggle'

  onDomRefresh: ->
    @$(@options.container).each (i, collapse) =>
      container = @$(collapse)
      items = @$(collapse).children(@options.item)

      # Applying behavior only when container height more then item height
      unless container.height() > items.first().outerHeight(true)
        return

      button = container
        .append(T[@options.btnTemplate])
        .children()
        .last()
        .addClass(@options.btnClass)

      width = container.width() - button.outerWidth(true)
      numOfHidden = 0
      buttonMoved = false
      items.each (index, item) =>
        width -= @$(item).outerWidth(true)
        if width < 0
          # Move button right behind the last visible item
          if not buttonMoved
            @$(item).before button
            buttonMoved = true
          @$(item).addClass('_collapsed').hide()
          numOfHidden++

      button.find('.button__text').text("#{App.t('global.more').toLowerCase()} #{numOfHidden}")

  _toggle: (event) ->
    event.stopPropagation()
    currentTarget = @$(event.currentTarget)
    currentTarget.closest(@options.container).find('._collapsed').toggle()
    currentTarget.attr('data-collapse-button', not JSON.parse(currentTarget.attr('data-collapse-button')))



