"use strict"

require "bootstrap"
require "views/header.coffee"
require "views/notify.coffee"
require "models/notify.coffee"

{ ModalRegion, OverModalRegion } = require "layouts/regions/modal.coffee"
SidebarRegion = require "layouts/regions/sidebar.coffee"
NotifyRegion = require "layouts/regions/notify.coffee"

App.module "Application",
  startWithParent: false
  define: (Application, App, Backbone, Marionette, $) ->

    class ApplicationLayout extends Marionette.LayoutView

      # ****************
      #  MARIONETTE
      # ****************
      template: "layout"

      ui:
        sidebar: "aside.sidebar"

      regions:
        content             : "#layout__content"
        header              : "#header"
        wrapper             : "#layout--wrapper"
        configuration_panel : ".layoutContent__message"
        sidebar_wrapper     : ".layoutContent__sidebar"
        modal               : ModalRegion
        modal2              : OverModalRegion
        notify              : NotifyRegion
        sidebar             : SidebarRegion

      # ***************
      #  BACKBONE
      # ***************
      initialize: ->
        @listenTo App.vent, "main:layout:show:in:content", (view, options) ->
          @content.show view, options

        App.reqres.setHandler "main:layout:get:offset:height", =>
          @content.$el.outerHeight()

      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onShow: ->
        # ## Выставляем высоту layout__content по размеру окна - высота header - padding

        self = @

        if App.Setting.get('product').indexOf('pdp') isnt -1
          @$el.addClass 'pdp'

        App.Layouts.Application.sidebar.on "show", ->
          @$el.css('opacity', '.3').fadeTo "fast", '1'

        App.Layouts.Application.content.on "show", ->
          @$el.css('opacity', '.3').fadeTo "fast", '1'

          $(window).resize self.resize_content

        App.Layouts.Application.header.show new App.Views.HeaderView
        App.Layouts.Application.notify.show new App.Views.Notify collection: new App.Models.Notify


      # ************
      #  PUBLIC
      # ************
      resize_content: ->
        App.trigger "resize", "window"
        App.Layouts.Application.content.trigger "resize",
          height: App.Layouts.Application.content.$el.height()
          width: App.Layouts.Application.content.$el.width()

        App.Layouts.Application.content.$el.trigger 'resize.treeview', size:
          height: App.Layouts.Application.content.$el.height()
          width: App.Layouts.Application.content.$el.width()

      stop: ->
        $(window).off "resize", self.resize_content

    Application.addInitializer ->
      App.Layouts.Application = new ApplicationLayout
      App.modal  = App.Layouts.Application.modal
      App.modal2 = App.Layouts.Application.modal2
      App.notify = App.Layouts.Application.notify

    Application.addFinalizer ->
      App.Layouts.Application.stop()
      delete App.Layouts.Application
