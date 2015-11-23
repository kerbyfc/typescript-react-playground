"use strict"

entry = require "common/entry.coffee"
style = require "common/style.coffee"
helpers = require "common/helpers.coffee"
require "behaviors/common/dialog.coffee"

App.Views.Controls ?= {}

class App.Views.Controls.Dialog extends Marionette.LayoutView

  behaviors: ->
    Dialog: size: 'short'

  tagName: "form"

  className: "form"

  templateHelpers: -> @options

  disableModalClose: true

class App.Views.Controls.DialogCreate extends App.Views.Controls.Dialog

  behaviors: ->
    behaviors = super

    behaviors.Form =
      listen         : @options.model
      syphon         : true
      isAutoValidate : true

    behaviors

  get: -> @serialize()

class App.Views.Controls.DialogEdit extends App.Views.Controls.DialogCreate

class App.Views.Controls.DialogDelete extends App.Views.Controls.Dialog

  template: 'controls/dialog/delete'

class App.Views.Controls.DialogTreeMove extends App.Views.Controls.Dialog

  template: 'controls/dialog/tree_move'

class App.Views.Controls.DialogGridMove extends App.Views.Controls.Dialog

  template: 'controls/dialog/grid_move'

class App.Views.Controls.DialogGridCopy extends App.Views.Controls.Dialog

  template: 'controls/dialog/grid_copy'

  ui: forAll: "[name=forAll]"

  get: -> @ui.forAll.prop("checked")

class App.Views.Controls.DialogSelect extends Marionette.LayoutView

  template: 'controls/dialog/select'

  tagName: "div"

  className: ""

  behaviors:
    Dialog: {}

  templateHelpers: ->
    action   : @options.action
    checkbox : @checkbox
    items    : @items

  currentView: null

  regions: content: "@ui.content"

  events:
    "click @ui.menu [data-item]": (e) ->
      e?.preventDefault()
      $node = $ e.currentTarget
      type = $node.data 'item'
      data = @data[type]

      return if $node.parent().hasClass style.className.active
      @ui.menu.children().removeClass style.className.active
      $node.parent().addClass style.className.active

      o =
        type      : type
        data      : data
        checkbox  : true
        popup     : true
        className : "popup__contentWrap"

      cap = App.Helpers.camelCase type, true
      o.collection = new App.Models.Entry[cap] if App.Models.Entry[cap]
      o.collection.source = @source if o.collection
      view = new App.Views.Entry[cap] o

      @listenTo view, "change:data", @onChangeData
      @content.show view
      o.collection.fetch reset: true

  ui:
    ok       : style.selector.button.success
    menu     : "[data-region=popup-menu]"
    checkbox : "[name=checkbox]"
    content  : "[data-region=popup-content]"

  initialize: (o) ->
    {@data, @items, @source, @type, @checkbox} = o

    parent = o.parent

    if o.data
      _.each o.data, (item) ->
        model = App.entry.get item.TYPE, item.ID
        item.content = model if not item.content and model

    @data = {}

    if @items
      @items = _.result @, 'items'
      @items = _.filter @items, (type) ->
        App.entry.can type: type
    else
      @items = _.result @model.collection, 'entries'

    @tab = {}
    _.each @items, (item) =>
      ext = _.result App.Views.Entry[App.Helpers.camelCase(item, true)]::, "ext"
      ext = ext ? [ item ]
      _.each ext, (extType) =>
        @tab[extType] = item

      data = _.filter o.data, (item) ->
        if ext.indexOf(item.TYPE) is -1 then false else true
      @data[item] = data

    @_data = _.filter o.data, (item) =>
      return false if @tab[item.TYPE] in @items
      true

  onChangeData: (o) ->
    if o
      type     = o.options.type
      selected = o.get()

      @data[type] = selected if selected

    @ui.ok.prop "disabled", not @options.preventSubmitDisabling
    @ui.menu.find '[data-item]'
    .each (i, node) =>
      arr = @data[node.dataset.item]
      node.dataset.count = arr.length if arr
      @ui.ok.prop "disabled", false if arr.length

  get: ->
    data  = []
    for i of @data
      data = data.concat @data[i]

    data = data.concat @_data
    [ data, @ui.checkbox.prop('checked') ]

  onShow: ->
    if @items.length
      @onChangeData()

      selector = if @options.default then "[data-item=#{@tab[@options.default]}]" else "[data-item]"
      @ui.menu.find selector
      .eq(0).trigger "click"
    else
      App.Notifier.showError
        title : App.t "menu.#{helpers.getCurrentModuleName()?.toLowerCase()}"
        text  : App.t "form.error.not_access", context: 'show'
        hide  : true

      @options.modal?.empty()
