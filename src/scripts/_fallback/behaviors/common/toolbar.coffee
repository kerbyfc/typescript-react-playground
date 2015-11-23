"use strict"

async = require "async"
entry = require "common/entry.coffee"
style = require "common/style.coffee"
helpers = require "common/helpers.coffee"
require "views/controls/dialog.coffee"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Toolbar extends Marionette.Behavior

  defaults:

    clearSelectionOnDelete: true

    action: (e, selected, type, action) ->
      module = App.currentModule?.moduleName
      return unless module

      # TODO: сделать наследование
      className = App.Views[module]?[helpers.camelCase(type, true) + _.capitalize(action)]
      className = className ? App.Views.Controls["Dialog#{helpers.camelCase(action, true)}"] if action isnt "create"

      # TODO: рефакторить. На текущий момент нет возможности изменить дефолтное поведение
      @[action]? e, selected, className

    getMessage: (action, type) ->

      options =
        postProcess : 'entry'
        entry       : type
        context     : "toolbar"

      title = App.t "#{action}",
        _.extend options, item: App.t("select_dialog.#{type}_plural_1").toLowerCase()

      data =
        title : title
        label : title

      data.label = '' if style.toolbar.visibleButton.indexOf(action) isnt -1
      data

  delete: (e, selected, className) ->
    return unless className
    type    = @type
    view    = @view
    options = @options

    modal = if App.modal.currentView then App.modal2 else App.modal
    modal.show new className
      modal    : modal
      selected : selected
      type     : type
      action   : "delete"
      callback : ->
        async.eachSeries selected, (model, callback) ->
          xhr = model.destroy wait: true
          if xhr
            xhr
            .fail (xhr) ->
              callback true, model

              # TODO: очередной хардкод с бекенда
              # выпилить когда будет корректная реализация ошибок
              key = 'delete'
              if entries = xhr?.responseJSON?.protected_entries?[0]
                entries = [entries] unless _.isArray entries
                count = entries.length

                entries = _.pluck entries, "DISPLAY_NAME"
                entries = entries.join ', '
                key += '_protected'

              App.Notifier.showError
                title : App.t "select_dialog.#{type}", context: "many"
                text  : App.t "form.error.#{key}",
                  item  : App.t("select_dialog.#{type}").toLowerCase()
                  items : entries
                  count : count
                  name  : model.getName()
                hide  : true
            .done ->
              callback null, model
          else
            # если удаляется локальная модель, без запросов к бекенду
            callback null, model
        , ->
          view.collection.fetch() unless view.tree
          if options.clearSelectionOnDelete
            view.clearSelection?()

        modal.empty()

  create: (e, selected, className) ->
    return unless className
    collection = @view.collection
    model = new collection.model null,
      collection: collection

    modal = if App.modal.currentView then App.modal2 else App.modal
    modal.show new className
      modal    : modal
      model    : model
      selected : selected
      action   : "create"
      checkbox : true
      type     : @type
      callback: (data, type) =>
        method = if model[type] then type else 'save'

        xhr = model[method] data,
          wait  : true
          action  : type
          success : (model) =>
            _.defer => @view.select? collection.get(model.id or model.cid)
            modal.empty()

        isTree = @view.tree
        xhr?.done? ->
          if isTree
            collection.add model
          else
            collection.fetch()

  edit: (e, selected, className) ->
    return unless className
    model = selected[0]

    modal = if App.modal.currentView then App.modal2 else App.modal
    modal.show new className
      modal    : modal
      model    : model
      selected : selected
      action   : "edit"
      type     : @type
      callback: (data, type) ->
        method = if model[type] then type else 'save'

        model[method] data,
          wait   : true
          validate : true
          action   : type
          success  : -> modal.empty()

  activate: (e, selected) ->
    _.each selected, (model) ->
      model.activate()

  deactivate: (e, selected) ->
    _.each selected, (model) ->
      model.deactivate()

  policy: (e, selected) ->
    return unless selected.length

    App.Policy?.createPolicy = _.map selected, (item) =>
      ID    : item.id
      NAME  : item.getName()
      TYPE  : @type
      content : item.toJSON()

    App.Routes.Application.navigate "/policy", trigger: true

  import: ->
    url    = _.result @view.collection.model::, 'urlRoot'
    module = App.currentModule.moduleName.toLowerCase()

    App.notify.fileupload
      acceptTypes: @view.collection.acceptTypes or null

      url : "#{url}/import"
      add : (e, data) ->
        options =
          type   : 'import'
          module : module
          status : 'send'

        App.notify.send
          files    : data.files
          options  : options
          formData : options

        App.Session.user.trigger "message:import", options

  export: ->
    url = _.result @view.collection.model::, 'urlRoot'
    module = App.currentModule.moduleName.toLowerCase()

    $.ajax
      url      : "#{url}/export"
      dataType : 'json'

    options =
      module : module
      type   : 'export'
      status : 'ready'

    App.Session.user.trigger "message:export", options

  onShow: ->
    attr = "data-toolbar-action"
    c = @view.collection

    el = @options.container
    if el
      @container = if _.isString el then $ el, @$el else $ el
    else
      @container = @$el

    @$button = @container.find "[#{attr}]"

    config = entry.getConfig c.model::
    type   = @type = @view.type or config?.type

    @$button.on "click", (e) =>
      e?.preventDefault()

      selected = c?.getSelectedModels?() or selected

      $el = $ e.currentTarget
      action = $el.data "toolbarAction"
      state  = $el.data "state"

      return if +state

      @view[action]? e, selected
      @view.trigger action, e, selected

      @options.action?.call @, e, selected, type, action

    @listenTo c, "select change", @update

    # TODO: продумать добавление
    table = @view.table or @view
    @listenTo table, "table:leave_edit_mode table:select update:toolbar", @update

    @listenTo table, "table:enter_edit_mode disable:toolbar", @disable

    @listenTo App.Configuration, "configuration:commit", @update
    @listenTo App.Configuration, "configuration:save", @update
    @listenTo App.Configuration, "configuration:rollback", @update
    @listenTo App.Configuration, "configuration:enter_edit_mode", @update
    @listenTo App.Configuration, "configuration:change:status", @update

    @update()

  disable: ->
    @$button.prop "disabled", true

  update: ->
    @$button.each (i, node) =>
      $node = $ node
      role  = action = $node.data "toolbarAction"

      # если нет привилегии на редактирование, даем привилегию на просмотр
      # потому что если есть привилегия на редактирование
      # привилегия на просмотр есть по умолчанию
      if @options.disableReadOnlyEdit is undefined or @options.disableReadOnlyEdit is false
        role   = 'show' if action is 'edit'

      check  = @view.collection.islock role

      if @options.disableReadOnlyEdit is undefined or @options.disableReadOnlyEdit is false
        action = 'show' if check and action is 'edit'

      message = @options.getMessage action, @type

      title = check?.message or message.title
      label = message.label

      $node
      .removeData 'content'
      .removeData 'state'
      .attr
        'data-content'    : if title is label then "" else title
        'data-popover-el' : 'toolbar'
        'data-state'      : check?.state or 0
      .text label
      .prop "disabled", !!(check?.state is 1)


  initialize: ->
    @listenTo(App.vent, 'disable:toolbar', @disable)
    @listenTo(App.vent, 'update:toolbar', @update)
