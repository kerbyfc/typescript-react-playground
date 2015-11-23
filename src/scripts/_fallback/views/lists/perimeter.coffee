"use strict"

helpers = require "common/helpers.coffee"

Perimeters = require "models/lists/perimeters.coffee"

class PerimeterItemView extends Marionette.ItemView

  template: "lists/perimeter_item"

  events:
    "click .delete_item": "delete"

  className: "perimeter__row"

  delete: (e) ->
    e.preventDefault()

    @model.collection.remove @model

  behaviors: ->
    Form:
      syphon: @options.model.toJSON()
      listen : @options.model

  onShow: ->
    if helpers.islock { type: 'perimeter', action: 'edit' }
      @$el.find('textarea, button').prop 'disabled', true

module.exports = class PerimeterView extends Marionette.CompositeView
  behaviors: ->
    Guardian:

      key: ->
        "lists:perimeter:#{@model.id}"

      title: ->
        action = @model.isNew() and 'add' or 'edit'
        App.t "lists.perimeters.perimeter_list_edit_dialog_title"

      urlMatcher: ->
        "lists/perimeters/#{@model.id}"

      attendNavigation: (fragment, match) ->
        if not match
          @model.navOnDestroy = fragment

      content: ->
        App.t "reports.cancel_confirm"

      # Mark back node in tree
      reject: ->
        @_markAsActive()

      restore: (model, data) ->
        model.set model.parse data

      accept: ->
        @model.rollback()
        # state was changed by activation another node in tree
        if @model.navOnDestroy
          App.vent.trigger "nav", @model.navOnDestroy

      omit: (urlPath) ->
        @destroy()


  template: "lists/perimeter"

  className: 'content'

  childView: PerimeterItemView

  childViewContainer: ".perimeter__form"

  events:
    'click ._success'  : 'save'

  ui:
    menu_select    : '[name="add_elem"]'
    menu           : '#menu'

  default:
    entries: ['person', 'group', 'resource']
    contacts: ['email', 'url', 'mobile', 'skype', 'icq', 'domain', 'lotus']

  # Send request to App.Controllers.PerimetersTree
  _markAsActive: =>
    App.reqres.request "lists:perimeters:tree:set:active", "#{@model.id}"
      #noEvents: true

  redrawMenu: (action, model) ->
    type = model.get 'type'

    switch action
      when 'add'
        @menu = _.filter @menu, (item) -> item.id isnt type

      when 'remove'
        @menu.push {id: type, text: App.t "lists.perimeters.#{type}" }

    if @menu.length is 0
      @ui.menu.hide()
    else
      @ui.menu.show()

  _parseData: ->
    entries = []
    contacts = []

    data = {
      EMAIL     : []
      DOMAIN    : []
      ICQ       : []
      SKYPE     : []
      MOBILE    : []
      URL       : []
      PERSON    : []
      GROUP     : []
      RESOURCE  : []
      LOTUS     : []
    }

    for item in @options.model.get('contacts').toJSON()
      contacts.push item.CONTACT_TYPE

      data[item.CONTACT_TYPE.toUpperCase()].push
        ID: item.VALUE
        TYPE: item.CONTACT_TYPE
        NAME: item.VALUE

    for item in @options.model.get('entries').toJSON()
      if item.ENTRY_TYPE is 'web_type'
        entries.push 'resource'

        data.RESOURCE.push
          ID: item.ENTRY_ID
          TYPE: 'resource'
          NAME: item.entry.DISPLAY_NAME
      else
        entries.push item.ENTRY_TYPE

        data[item.ENTRY_TYPE.toUpperCase()].push
          ID: item.ENTRY_ID
          TYPE: item.ENTRY_TYPE
          NAME: item.entry.DISPLAY_NAME

        if item.USE_EMPLOYEE_CONTACTS_ONLY is 1
          data["#{item.ENTRY_TYPE.toUpperCase()}_USE_EMPLOYEE_CONTACTS_ONLY"] = item.USE_EMPLOYEE_CONTACTS_ONLY

    entries   = _.uniq entries
    contacts  = _.uniq contacts

    [data, entries, contacts]

  initialize: ->
    @menu = []

    [data, @entries, @contacts] = @_parseData()

    for elem in _.union @default.contacts, @default.entries
      if elem not in @contacts and elem not in @entries
        @menu.push {id: elem, text: App.t "lists.perimeters.#{elem}" }

    @collection = new Perimeters.PerimeterItems

    for entry in _.union @entries, @contacts
      d = {}
      d.type = entry
      d[entry.toUpperCase()] = data[entry.toUpperCase()]

      if data["#{entry.toUpperCase()}_USE_EMPLOYEE_CONTACTS_ONLY"]
        d["#{entry.toUpperCase()}_USE_EMPLOYEE_CONTACTS_ONLY"] = data["#{entry.toUpperCase()}_USE_EMPLOYEE_CONTACTS_ONLY"]

      @collection.add d

  onShow: ->
    return if helpers.islock { type: 'perimeter', action: 'edit' }

    @_markAsActive()
    @ui.menu_select.select2
      placeholder: App.t('lists.perimeters.add_element')
      allowClear: true
      data: => return {results: @menu}
    .on 'select2-selecting', (e) =>
      e.preventDefault()

      $(e.target).select2('close')

      @collection.add {type: e.val}

    @listenTo @collection, 'add', _.bind @redrawMenu, @, 'add'
    @listenTo @collection, 'remove', _.bind @redrawMenu, @, 'remove'

  save: (e) ->
    e.preventDefault()

    data = @children.reduce (acc, view) ->
      acc = _.merge acc, view.getData()
      acc
    , {}

    entries  = @model.get 'entries'
    contacts = @model.get 'contacts'
    ids = []

    # Добавляем новые персоны и группы
    for type in @default.entries
      type = type.toUpperCase()

      if data[type]
        for item in data[type]
          entries.add
            PERIMETER_ID        : @model.id
            ENTRY_TYPE          : if item.TYPE is 'resource' then 'web_type' else item.TYPE.toLowerCase()
            ENTRY_ID          : item.ID

      # Получаем ID всех текущих сущностей
      ids = _.union(_.pluck(data.PERSON, 'ID'), _.pluck(data.GROUP, 'ID'), _.pluck(data.RESOURCE, 'ID'))

    for entry in entries.toJSON()
      if entry.ENTRY_ID in ids
        if entry.ENTRY_TYPE isnt 'web_type'
          entries.get(entry.ENTRY_ID).set
            USE_EMPLOYEE_CONTACTS_ONLY : data[entry.ENTRY_TYPE.toUpperCase() + '_USE_EMPLOYEE_CONTACTS_ONLY']
      else
        entries.remove entries.get(entry.ENTRY_ID)

    ids = []
    for type in @default.contacts
      contact_type = type
      type = type.toUpperCase()

      if data[type]
        for entry in data[type]
          ids = _.union ids, _.pluck data[type], 'ID'

          contacts.add
            PERIMETER_ID : @model.id
            CONTACT_TYPE : contact_type
            VALUE    : entry.ID

    # Выкидываем удаленные контакты
    for contact in contacts.toJSON()
      if contact.VALUE not in ids
        contacts.remove contacts.get(contact.VALUE)

    @model.save null,
      success: (model, resp, options) ->
        App.Notifier.showSuccess({
          title: App.t('menu.perimeters')
          text: App.t 'lists.perimeters.saved',
            perimeter: model.get('DISPLAY_NAME')
          hide: true
        })
      error: (model, resp, options) ->
        App.Notifier.showError({
          title: App.t('menu.perimeters')
          text: App.t 'lists.perimeters.error',
            perimeter: model.get 'DISPLAY_NAME'
          hide: true
        })
