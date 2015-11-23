"use strict"

require "common/backbone-validation.coffee"
require "backbone.paginator"
style = require "common/style.coffee"

class App.Common.BackbonePaginationItem extends App.Common.ValidationModel

  constructor: (attrs) ->
    super

    collection = @collection
    return unless collection
    section = collection.section

    if section
      @sectionIdAttribute = section.idAttribute
      # @model2sectionAttribute = "#{@type}2#{section.type}"

    @setCollections @attributes

    @on "change", (o) ->
      # TODO: продумать поведение при изменении модели без запросов на бекенд;

    @on "sync", (o, data) ->
      # если модель в коллекции, сработает обработчик коллекции
      if collection
        if section?.count and
        c = @previous @model2sectionAttribute
          @getModel2Section().each (item) ->
            return if c.get item.id
            m = section.collection.get item.id
            ++collection.total_count if m is section
            m.count +m.count()+1
          c.each (item) ->
            return if o.getModel2Section().get item.id
            m = section.collection.get item.id
            --collection.total_count if m is section
            m.count +m.count()-1

          section.collection.trigger 'change', section

        unless @previous(@idAttribute)
          ++collection.total_count
          if section?.count
            section.count(+section.count()+1)

            section.collection.trigger 'change', section
        return

      return unless data # если нет данных с бекенда, к примеру при удалении модели
      return if _.isArray(data) and data.length is 0 # если модель удалена, приходит пустой массив
      App.entry.add o.attributes # добавляем/обновляем сущность

    @on "destroy", (model) ->
      model.off "sync"
      if collection
        --collection.total_count if collection.total_count
        if section?.count?
          section.count(+section.count()-1)

          section.collection.trigger 'change', section

      App.entry.remove model

  validation:
    DISPLAY_NAME: [
      required : true
      msg    : App.t 'form.error.field_required'
    ,
      rangeLength : [1, 256]
      msg     : App.t 'form.error.name_length'
    ]
    NOTE: [
      required: false
    ,
      rangeLength : [0, 1000]
      msg     : App.t 'form.error.note_length'
    ]

  defaults:
    DISPLAY_NAME : ""
    NOTE     : ""

  checksumAttribute: "FILE_CHECKSUM"

  destroy: ->
    section = @collection.section
    t2c     = @getModel2Section()

    if ( not t2c or t2c.length is 1 ) and +@get('IS_SYSTEM') isnt 1
      pd = @get 'protected_documents'
      if pd?.length
        message = pd.map (model) ->
          if model and model.getName then model.getName() else model.DISPLAY_NAME

        App.Notifier.showError
          title : App.t "analysis.#{@type}.delete_dialog_title"
          text  : App.t "analysis.#{@type}.delete_protected_object_constraint",
            name              : @get 'DISPLAY_NAME'
            protected_objects : message.join ', '
          hide: true
        return

      super
    else
      t2c = _.filter t2c.toJSON(), (item) ->
        return true if item[section.idAttribute] isnt section.id
        false

      (o = {})[@model2sectionAttribute] = t2c

      @save o,
        wait  : true
        success : (model) =>
          @collection.remove model
        error: (model, collection, options) =>
          App.Notifier.showError
            title : App.t "select_dialog.#{@type}"
            text  : App.t "form.#{@type}.delete",
              item : App.t("select_dialog.#{@type}_plural_1")
              name : @getName()
            hide: true

  error: (err, models) ->
    model = models?[0]
    # TODO: порефакторить
    # во многом упирается на правильную реализацию ошибок бекенда
    if model and section = @collection.section

      (o = {})[@sectionIdAttribute] = section.id
      if _.find(model[@model2sectionAttribute], o)
        if @nameAttribute of err
          field = @nameAttribute
          error = "form.error.contstraint_violation3"
        if @checksumAttribute of err
          field = @checksumAttribute
          error = "form.error.contstraint_violation1"

        __section__ = App.t "select_dialog.#{section.type}", context: 'in'
        __section__ = __section__.toLowerCase() + " <b>#{section.getName()}</b>"
        message = App.t error,
          item  : App.t "select_dialog.#{@type}"
          section : __section__

        err[field] = [ message ]
        return err
      else
        if @nameAttribute of err
          field = @nameAttribute
          error = "form.error.contstraint_violation4"
        else if @checksumAttribute of err
          field = @checksumAttribute
          error = "form.error.contstraint_violation2"

        arr = []
        for m in model[@model2sectionAttribute]
          item = section.collection.get m[@sectionIdAttribute]
          arr.push item.getName()

        m = App.t "select_dialog.#{section.type}",
          context: if arr.length > 1 then "in_many" else "in"

        message = App.t error,
          item   : App.t "select_dialog.#{@type}"
          section  : m.toLowerCase()
          sections : "<b>#{ arr.join("</b>,<b>") }</b>"

        @trigger "copy", model
        @dupModel = model

        err[field] = [ message ]
        return err
    err

  onCellCanEdit: (field) -> true

  inlineSave: (field, value, o) ->
    (data = {})[field] = value
    @save data, o

  getModel2Section: ->
    @get @model2sectionAttribute

  getSection: ->
    @getModel2Section().get(@collection.section.id) or null

  save: (key, val, options) ->
    if key is null or typeof key is 'object'
      attrs = key
      options = val
    else
      (attrs = {})[key] = val

    if attrs
      @modifyRequest? attrs, options
      @setCollections attrs

    super attrs, options

  set: (key, val, options) ->
    if key is null or typeof key is 'object'
      attrs = key
      options = val
    else
      (attrs = {})[key] = val

    @modifyRequest? attrs, options if attrs
    @setCollections attrs
    super attrs, options

  collections: ->
    section = @collection?.section
    return unless section

    (o = {})[@model2sectionAttribute] = Backbone.Collection.extend
      model: Backbone.Model.extend idAttribute: section.idAttribute
    o

  setCollections: (attrs) ->
    for key of data = _.result(@, 'collections')
      m2c = attrs[key]
      if m2c and _.isArray m2c
        attrs[key] = new data[key] m2c, section: @
        # App.entry.add attrs[key]
        # TODO: надо триггать родительскую модель если изменилась коллекция внутри модели
        # attrs[key].section = @
        # attrs[key].sectionAttribute = key
        # @listenTo attrs[key], "update reset change", (collection) ->
        #   collection.section.trigger "change", arguments...
        #   collection.section.trigger "change:#{collection.sectionAttribute}", arguments...

  setStatus: (status) ->
    if t2c = @getModel2Section()?.toJSON()

      (o = {})[@sectionIdAttribute] = @collection.section.id
      d2c = _.find t2c, o

      return unless d2c
      d2c.ENABLED = status
      (o = {})[@model2sectionAttribute] = t2c
    else
      o = ENABLED: status

    @save o,
      wait  : true
      error : (model) ->
        App.Notifier.showError
          title : App.t "select_dialog.#{@type}", context: "many"
          text  : App.t 'form.error.change_status',
            item : App.t("select_dialog.#{@type}", context: "title").toLowerCase()
            name : model.getName()
          hide  : true

  activate: -> @setStatus 1

  deactivate: -> @setStatus 0

  move: (dest, callback, copy) ->
    t2c = @getModel2Section().toJSON()

    (o = {})[@sectionIdAttribute] = dest.id
    isDest = _.find t2c, o
    return false if isDest and not copy

    o[@sectionIdAttribute] = @collection.section.id
    source = _.find t2c, o

    if copy
      if isDest
        # Если элемент уже присутствует в секции, копируем свойства
        _.extend isDest, source
        isDest[@sectionIdAttribute] = dest.id
        isDest.ENABLED = dest.get 'ENABLED'
      else
        # Если элемента нет в секции, добавляем
        opt = _.extend {}, source
        opt[@sectionIdAttribute] = dest.id
        t2c.push opt
        opt.ENABLED = dest.get 'ENABLED'
    else
      source[@sectionIdAttribute] = dest.id
      source.ENABLED = dest.get 'ENABLED'

    (o = {})[@model2sectionAttribute] = t2c

    @save o,
      wait: true
      success: =>
        @collection.fetch() unless copy
        # @collection.remove @ unless copy
        callback?()
      error: =>
        @fetch()
        label = App.t 'form.error.drag',
          item : App.t("select_dialog.#{@type}_plural_2").toLowerCase()
        callback? label

  copy: (dest, callback) ->
    @move dest, callback, true

  toJSON: ->
    data = super

    # TODO: вынести в общий класс
    for k of data
      data[k] = data[k].toJSON arguments... if data[k]?.toJSON

    data

class App.Common.BackbonePagination extends Backbone.Paginator.requestPager

  constructor: ->
    super
    App.currentModule?.collections.push @

    @listenTo @, "sync", (o) ->
      return unless o
      if _.isUndefined(@searchQuery) or # не используется поиск
      not o.searchQuery # если поиск пустой TODO: переделать в дальнейшем
        o.section?.count? o.total_count
      App.entry.add o.models or o.attributes # добавляем/обновляем модели или модель

  getTotalLength: -> @total_count

  timeoutAutoRefresh: 5000

  getSection: -> @section or null

  config: ->
    name = @model::nameAttribute

    default:
      sortCol   : name
      sortable  : false
      draggable : false
      checkbox  : true

    columns: [
      id      : name
      name    : App.t "global.NAME"
      field   : name
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter : (row, cell, value, columnDef, dataContext) ->
        """#{dataContext.getName()}"""
    ,
      id      : "NOTE"
      name    : App.t "global.NOTE"
      resizable : true
      sortable  : true
      minWidth  : 150
      field   : "NOTE"
    ]

  initialize: (o) ->
    proto  = @model::
    @entry = App.entry.getConfig proto

    @type  = proto.type or @entry?.type
    super

  search: (o) ->
    @fetch o

  pageSizes: [10, 50, 100, 1000]

  pagesInRange : 5

  paginator_ui:
    firstPage : 0
    currentPage : 0
    perPage   : 10

  paginator_core:
    url: ->
      sortRule = @sortRule
      _default = _.result(@, 'config')?.default
      if not sortRule and _default?.sortCol
        sortRule = {}
        (sortRule.sort = {})[_default.sortCol] = _default.sortDirection or 'asc'

      if @type and @type is 'query'
        url = "#{App.Config.server}/api/search?type=query&scopes=#{@entry.url}&start=#{@currentPage * @perPage}&limit=#{@perPage}"
      else
        url = "#{App.Config.server}/api/#{@entry.url}?start=#{@currentPage * @perPage}&limit=#{@perPage}"

      url += "&#{$.param(@filterData)}" if @filterData
      url += "&#{$.param(sortRule)}" if sortRule
      url

    dataType: "json"

  sortCollection: (args) ->
    data = {}
    data.sort = {}
    data.sort[args.field] = args.direction

    @sortRule = data

    @fetch reset: true

  reset : ->
    App.entry.remove @
    @total_count = 0 unless @length
    super

  parse: (resp) ->
    @total_count = resp.totalCount
    @totalPages = Math.ceil(resp.totalCount / @perPage)
    if resp.rowNum
      @currentPage = Math.ceil(resp.rowNum / @perPage) - 1

    data = super
    data = data[@entry.url] if @type and @type is 'query'
    data

class App.Common.BackboneLocalPagination extends App.Common.BackbonePagination

  fetch: -> false

  getTotalLength: -> @length

  sortCollection: (args) ->
    @comparator = args.field
    @sort()
    if args.direction is "desc"
      @reset @toJSON().reverse(), sort: false

  search: (data) ->
    nameAttribute = @model::nameAttribute
    idAttribute = @model::idAttribute
    query = data.data?.filter?[nameAttribute]?.replace(/[*]/g, '')

    @_collection ?= []
    collection = @_collection.concat @toJSON()
    @_collection = []
    items = []

    if query
      _.each collection, (model) =>
        name = @get(model[idAttribute])?.getName() or model[nameAttribute]
        if name.toUpperCase().indexOf(query.toUpperCase()) >= 0
          items.push model
        else
          @_collection.push model
    else
      items = collection

    @reset items
    @trigger 'search:loading', false

  config: ->
    default:
      sortCol   : name
      sortable  : false
      draggable : false
      checkbox  : false

    columns: [
      id        : "id"
      name      : ""
      field     : "id"
      minWidth  : 150
      resizable : false
      cssClass  : "center"
      sortable  : true
      formatter : (row, cell, value, columnDef, dataContext) ->
        type = dataContext.get('TYPE').toLowerCase()

        Marionette.Renderer.render "controls/entry/label",
          type  : type
          label : dataContext.t type, context: 'type'
          image : App.entry.getImagePath dataContext.toJSON()
    ,
      id        : "NAME"
      name      : App.t "global.NAME"
      field     : "NAME"
      resizable : true
      sortable  : true
      minWidth  : 150
    ,
      id        : "remove"
      name      : ""
      field     : "remove"
      width     : 40
      resizable : false
      cssClass  : "center"
      formatter : (row, cell, value, columnDef, dataContext) ->
        id = dataContext.id or (dataContext.get('TYPE') + dataContext.get('ID'))
        Marionette.Renderer.render "controls/grid/button_remove", id: id
    ]
