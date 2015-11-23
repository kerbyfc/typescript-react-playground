"use strict"

LdapUser = require "models/settings/user_ad.coffee"
LdapServers = require "models/settings/adconfig.coffee"

module.exports = class ImportUserDialog extends Marionette.LayoutView

  _t = (key, data = {}) ->
    App.t "settings.#{key}", data

  _options =

    placeholders:
      server: _t 'ldap_settings.users_ldap_import_placeholder'

    # table options
    table:
      options:
        checkbox: true
        sortCol: "NAME"

      # default column options
      default:
        resizable : true
        sortable  : true
        minWidth  : 150

      # column options
      columns:
        NAME: {}
        DEPARTMENT: {}

  template: "settings/dialogs/import_user"

  templateHelpers: ->
    modal_dialog_title: @title

  regions:
    usersTableRegion : "#users_table"

  events:
    "click [data-action='save']"  : "save"
    "click [data-action='search']"  : "search"

  ui:
    "adServers"  : ".ad_servers_list"
    "searchInput" : ".ad_servers_search"

  initialize: (options) ->
    # make refs to some options
    _.extend @, _.pick options, 'callback', 'title'

    @usersCollection = new LdapUser.Collection()
    @serversCollection = new LdapServers.Collection()

    @initTable()

  initTable: ->
    @usersTable = new App.Views.Controls.TableView
      collection: @usersCollection
      config:
        default: _options.table.options
        columns: _.map _options.table.columns, (opts, id) ->
          _.extend {}, _options.table.default, opts,
            id: id,
            field: id
            name: _t "users.#{id.toLowerCase()}_column"

  search: (e) ->
    e?.preventDefault()
    @usersCollection.fetch
      reset: true
      data:
        server_id: @ui.adServers.select2('data')?.id
        query: @ui.searchInput.val()
      error: (model, resp, options) ->
        switch resp.responseText
          when "ldap_server_connection_error"
            error = App.t 'settings.users.failed_connect_to_ldap_error'
          else
            error = App.t 'settings.users.failed_import_ldap_user_error'

        App.Notifier.showError
          title: App.t 'settings.users_tab'
          text: error
          hide: false

  save: (e) =>
    e.preventDefault()
    @callback? @usersTable.getSelectedModels(), @ui.adServers.select2('data')?.id
    @destroy()

  onShow: =>
    @ui.adServers.select2
      minimumResultsForSearch: -1
      query: (query) =>
        @serversCollection.fetch
          reset: true
          success: (collection) =>
            @onServerChange query, collection

      placeholder: _options.placeholder

    # Рендерим контролы
    @usersTableRegion.show @usersTable

    @usersTable.resize 500, 700

  onServerChange: (query, collection) ->
    data = if query.term is ''
      collection
    else
      collection.filter (server) ->
        server.get('display_name').toUpperCase().indexOf(query.term.toUpperCase()) >= 0

    query.callback
      more: false
      results: data.map (server) ->
        id: server.get('name'), text: server.get 'display_name'
