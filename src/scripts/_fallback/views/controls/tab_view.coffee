"use strict"

App.Views.Controls ?= {}

class App.Views.Controls.TabChildView extends Marionette.ItemView

  template: "controls/tab/tab_item"

  triggers:
    "click .tabable--delete"                                : "remove:tab"
    "click [data-action='add-tab']:not('.button-disabled')" : "tab:edit"

  events:
    "keypress [type='text']"  : "saveOnEnter"
    "click"                   : "tab_clicked"

  tab_clicked: (e) ->
    e.preventDefault()

    if (
      not ( "button-delete" in e.target.classList )  and
      not ( "i-edit" in e.target.classList )  and
      not ( "active" in @el.classList )
    )
      @trigger "before:tab:clicked", @

  saveOnEnter: (e) ->
    code = if e.keyCode then e.keyCode else e.which
    if code is 13
      @trigger 'tab:edit', @

  tagName: "li"

  deleteActiveClass: ->
    @$el.removeClass "active"

  initialize: (options) ->
    @options = options

    if options.childViewTemplate
      @template = options.childViewTemplate

  render: ->
    super()

    if @options.tabItemClass
      @$el.addClass @options.tabItemClass


class App.Views.Controls.TabView extends Marionette.CompositeView

  template: "controls/tab/tabs"

  regions:
    tabContent: ".tab-content"

  childView: App.Views.Controls.TabChildView

  childViewContainer: "ul.tab-list"

  childViewOptions: (model, imdex) ->
    return @options

  attachHtml: (cv, iv, index) ->
    $container = @getChildViewContainer(@)
    element = $container.find("li:eq(#{index})")

    if element.length is 0
      $container.append(iv.el)
    else
      element.before(iv.el)

  events:
    'keypress .tabable--add' : "onKeyPress"

  triggers:
    "click .tabable--save:not('.button-disabled')" : 'tab:add'
    "click .tabable--add"  : 'tab:add'

  onKeyPress: (e) ->
    code = if e.keyCode then e.keyCode else e.which
    if code is 13
      @trigger 'tab:add', @

  initialize: (options) ->
    @_show = false
    @params = {}
    @params.label = if options and options.displayKey then options.displayKey else 'label'
    @params.id = if options and options.idKey then options.idKey else 'name'
    @params.icon = if options and options.idIcon then options.idIcon else 'icon'

    @options = options
    @swapViews = new Backbone.ChildViewContainer()
    @regionManager = new Marionette.RegionManager()

    defaults =
      parentEl: =>
        @$el

    @regions = @regionManager.addRegions(@regions, defaults)

    if not @collection and options.tabs
      @collection = new Backbone.Collection()

      _.each options.tabs, (tab) =>
        data = {}
        data[@params.id] = _.result tab, "name"
        data[@params.label] = _.result tab, "label"
        data[@params.icon] = _.result tab, "icon"
        @collection.add data

    if options and options.views
      _.each options.views, (view, name) =>
        @swapViews.add view, name

  addView: (view, name) ->
    view.name = name
    @swapViews.add view, name

  removeTabByView: (view) ->
    @swapViews.remove view

  removeTabByName: (name) ->
    @swapViews.remove @swapViews.findByCustom(name)

  onDestroy: ->
    @_show = false
    # Сбрасываем регион
    @regions.tabContent.reset()

  onRenderCollection: ->
    @showInitialTab()

  showInitialTab: ->
    if @collection.length isnt 0 and @_show
      # Если задана базовая вьюха для всех Tab
      if @options and @options.baseView
        if @collection.length > 0
          currentTabModel = if @options.initialTab then @collection.get(@options.initialTab) else @collection.at(0)
          view = new @options.baseView {model: currentTabModel}
      else
        # Если задана начальная - показываем ее
        if (@options and @options.initialTab)
          currentTabModel = @collection.findWhere
            name: @options.initialTab

          view = @swapViews.findByCustom(@options.initialTab)
        # иначе - первую вкладку коллекции view
        else
          currentTabModel = @collection.at(0)
          view = @swapViews.findByIndex(0)

      if currentTabModel and view
        if @triggerMethod("before:tab_changed", view, currentTabModel.get('name')) isnt false
          @currentView = view

          view = @children.findByModel currentTabModel

          view.$el.addClass "active"
          @currentView.delegateEvents()
          @regions.tabContent.show @currentView, preventDestroy : true

          @triggerMethod("after:tab_changed", @currentView)

  onShow: ->
    @_show = true

    @collection.on 'add', (model, collection, options) =>
      _.defer =>
        if @options and @options.baseView
          @currentView = new @options.baseView {model: model}
        else
          @currentView = @children.findByModel model

        @children.call "deleteActiveClass"
        (@children.findByModel model).$el.addClass "active"

        @currentView.delegateEvents()
        @regions.tabContent.show @currentView, preventDestroy : true

        @triggerMethod("after:tab_changed", @currentView)

    @collection.on 'remove', (model, collection, options) =>
      if options.index isnt 0
        next_model = collection.at(options.index - 1)
      else
        next_model = collection.at(if collection.length is 1 then 0 else options.index + 1)

      if next_model and @currentView.model.id is model.id
        if @options and @options.baseView
          @currentView = new @options.baseView {model: next_model}
        else
          @currentView = @children.findByModel next_model

        @children.call "deleteActiveClass"
        (@children.findByModel next_model).$el.addClass "active"

        @currentView.delegateEvents()
        @regions.tabContent.show @currentView, preventDestroy : true
      else
        @regions.tabContent.empty() if @collection.length is 0

    @showInitialTab()

    if @options.draggable
      @$el.find(".tabable").sortable
        axis: "x"
        containment: "document"
        scroll: false
        stop: (event, ui) =>
          _($(@childViewContainer).find('li')).each (tab) ->
            debug tab
          debug @collection
          @trigger 'reorder:finish', @

  onChildviewBeforeTabClicked : (childView) ->
    if @triggerMethod("before:tab:clicked", childView) isnt false
      @triggerMethod "childview:tab:clicked", childView

  onChildviewTabClicked : (childView) ->
    if @options and @options.baseView
      view = new @options.baseView {model: childView.model}
      _preventDestroy = false
    else
      view = @swapViews.findByCustom(childView.model.get @params.id)
      _preventDestroy = true

    # Если это уже не открытый Tab - показываем его
    if (@currentView isnt view)
      if @triggerMethod("before:tab_changed", view, childView.model.get 'name') isnt false

        @currentView = view
        @currentView.delegateEvents()
        @regions.tabContent.show @currentView, preventDestroy : _preventDestroy

        @triggerMethod("after:tab_changed", @currentView)

    @children.call "deleteActiveClass"
    childView.$el.addClass "active"

  onChildviewRemoveTab : (childView) ->
    App.Helpers.confirm
      title: @locale.tab_delete_dialog_title
      data: @locale.tab_delete_dialog_question
      accept: ->
        childView.model.destroy()
