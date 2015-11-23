"use strict"

require "views/controls/table_view.coffee"
helpers = require "common/helpers.coffee"

EthDialog = require 'views/settings/setup/eth_dialog.coffee'
GlobalNetworkDialog = require 'views/settings/setup/global_network_dialog.coffee'

App.module "Settings.Setup",
  define: (Setup, App, Backbone, Marionette, $) ->

    App.Views.Settings ?= {}

    class NetworkGlobal extends Marionette.ItemView

      template: 'settings/setup/network/global_network'

      className: 'form _viewOnly'

      tagName: 'form'

      modelEvents:
        'sync': 'render'

      triggers :
        "click @ui.change" : "changeGlobal"

      ui:
        change: "[data-action='change_global']"

      _blockToolbar: ->
        @ui.change.prop "disabled", true

      _updateToolbar: ->
        @_blockToolbar()

        if helpers.can({type: 'network', action: 'edit'})
          @ui.change.prop "disabled", false

      onRender: ->
        @_updateToolbar()

    class NetworkInterfaces extends Marionette.LayoutView

      template: 'settings/setup/network/eth'

      triggers :
        "click @ui.change_eth" : "changeEth"

      regions:
        eth_table: '#eth_table'

      ui:
        change_eth: "[data-action='change_eth']"

      blockToolbar: ->
        @ui.change_eth.prop('disabled', true)

      updateToolbar: ->
        selected = @eth_table_.getSelectedModels()

        @blockToolbar()

        if selected.length is 1 and helpers.can({type: 'network', action: 'edit'})
          @ui.change_eth.prop('disabled', false)

      onShow : ->
        @eth_table.show @eth_table_

        @listenTo @eth_table_, "table:select", @updateToolbar

        @eth_table_.resize App.Layouts.Application.content.$el.height() - 100

        @updateToolbar()

      initialize: ->
        @eth_table_ = new App.Views.Controls.TableView
          collection: @collection
          config:
            name: "ethTable"
            default:
              sortCol: "name"
            columns: [
              {
                id          : "name"
                name        : App.t 'settings.network.interface'
                field       : "name"
                resizable   : true
                minWidth    : 100
              }
              {
                id          : "ipaddr"
                name        : App.t 'settings.network.ipaddr'
                resizable   : true
                minWidth    : 120
                field       : "ipaddr"
              }
              {
                id          : "netmask"
                name        : 'Маска'
                resizable   : true
                sortable    : true
                minWidth    : 150
                field       : "netmask"
              }
              {
                id          : "gateway"
                name        : App.t 'settings.network.gateway'
                resizable   : true
                minWidth    : 150
                field       : "gateway"
              }
              {
                id          : "bootproto"
                name        : App.t 'settings.network.bootproto'
                resizable   : true
                minWidth    : 50
                field       : "bootproto"
                formatter   : (row, cell, value, columnDef, dataContext) ->
                  if parseInt(dataContext.get(columnDef.field), 10) is 1
                    "<span class='protected__itemIcon _active'></span>"
                  else
                    "<span class='protected__itemIcon _inactive'></span>"
              }
            ]

    class App.Views.Settings.SetupNetwork extends Marionette.LayoutView

      # ****************
      #  MARIONETTE
      # ****************
      regions :
        eth: '#eth'
        global_network: '#global_network'

      template  : "settings/setup/network/network"
      className : 'content__indent'

      onShow : ->
        NetworkInterfacesView = new NetworkInterfaces collection: @model.networks_collection
        NetworkGlobalView = new NetworkGlobal model: @model

        NetworkGlobalView.on 'changeGlobal', =>
          App.modal.show new GlobalNetworkDialog
            title: App.t 'settings.network.global_network_title'
            model: @model
            callback: (data) ->
              @model.validate data

              if @model.isValid()
                # Make data processing AFTER validation, because Backbone.Validate change callback aliases defined in model.validation
                _.each data, (value, key) ->
                  data[key] = _.compact value.split '\n'

                @model.set data
                .save_settings()
                .fail ->
                  throw new Error "Can't save global network settings"
                .always ->
                  App.modal.empty()

        NetworkInterfacesView.on 'changeEth', (options) =>
          model = options.view.eth_table_.getSelectedModels()[0]

          App.modal.show new EthDialog
            title: App.t 'settings.network.eth_network_title',
              eth: model.get 'name'
            model: model
            close: ->
              model.rollback()
            callback: (data) =>
              model.set data
              model.backup()

              if not model.validate()

                App.Helpers.confirm
                  title: App.t 'settings.network.confirm-save__title'
                  data: App.t 'settings.network.confirm-save__msg'
                  accept: =>
                    @model.save_settings()
                    .done ->
                      App.modal.empty()
                    .fail ->
                      throw new Error("Can't save eth settings")
                      App.modal.empty()
                  reject: ->
                    model.rollback()

        @eth.show NetworkInterfacesView
        @global_network.show NetworkGlobalView
