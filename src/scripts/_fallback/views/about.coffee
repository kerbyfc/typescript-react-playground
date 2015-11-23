"use strict"

App.module "Application",
  startWithParent: true
  define: (Application, App, Backbone, Marionette) ->

    class App.Views.AboutDialog extends Marionette.ItemView

      template: "about"

      templateHelpers: ->
        version: @options.version
        type: ->
          product = App.Setting.get 'product'
          if product.indexOf('e') isnt -1
            product_subtype = App.t 'global.product_types.e'

          if product.indexOf('s') isnt -1
            product_subtype = App.t 'global.product_types.s'

          installation_type = ''
          if product.indexOf('a') isnt -1
            installation_type = App.t 'global.product_types.a'

          "#{product_subtype} #{installation_type}"
