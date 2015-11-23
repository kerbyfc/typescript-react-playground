"use strict"

App.module "Application",
  startWithParent: false

  define: (Module, App) ->

    class App.Views.NotifyItem extends Marionette.ItemView

      tagName: "li"

      className: "inProgressItem"

      template: "notify_item"

      modelEvents:
        change: -> @render()

    class App.Views.Notify extends Marionette.CompositeView

      template: "notify"

      className: "inProgress__indent"

      childView: App.Views.NotifyItem

      childViewContainer: "[data-ui-content]"

      ui: reset: "[data-action-reset]"

      events:
        "click @ui.reset": (e) ->
          @collection.reset()
          @getChildViewContainer @
          .html ""

      attachHtml: (cv, iv) ->
        attr = 'data-block'

        name = type = iv.model.get 'type'
        name = iv.model.get 'action' unless name

        $container = @getChildViewContainer @
        $block = $container.find "[#{attr}='#{name}']"

        unless $block.length
          if type
            block = type
            title = App.t "select_dialog.#{type}", context: "many"
          else
            block = iv.model.get 'action'
            title = App.t "global.#{block}"

          html = Marionette.Renderer.render "notify_section",
            title : title
            block : block

          $block = $ html
          .appendTo $container

        $block.find('[data-ui-list]').append iv.el
