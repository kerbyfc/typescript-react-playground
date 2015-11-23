"use strict"

App.Views.Controls ?= {}

class App.Views.Controls.FormView extends Marionette.ItemView
  # ToDo: Отнаследовать потом все диалоги-формы от данной вьюхи
  showErrorHint: (elem, error) ->
    if elem
      element = @$("[name='#{elem}']")

      if element.data("popover")
        element.popover("destroy")

      position = element.data("tooltip-position") or "right"

      element.popover(
        placement: position
        trigger: "manual"
        content: error
        container: element.closest("[data-error-container]")
      )
      element.popover('show')
    else
      if @noty
        @noty.remove()

      @noty = App.Notifier.showError
        text  : error
        delay : 4000

  onDestroy: ->
    App.Common.ValidationModel::.unbind(@)

  onShow: ->
    App.Common.ValidationModel::.bind(@)
