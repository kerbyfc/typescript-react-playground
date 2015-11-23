"use strict"

helpers = require "common/helpers.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.Rule extends Marionette.LayoutView

      template: 'policy/sidebar/rule'

      templateHelpers: ->
        type: @options.type

      modelEvents:
        "request": ->
          @model.get('DATA').trigger "request", arguments...

        "error": ->
          App.Notifier.showError
            hide  : true
            title : App.t "select_dialog.policy", context: "many"
            text  : App.t "save",
              postProcess : "entry"
              entry       : "policy"
              context     : "error"

      className: "sidebar__content"

      events:
        "click @ui.save" : "save"
        "click @ui.back" : "back"

      ui:
        save   : "[data-action=save]"
        back   : "[data-action=back]"
        rule   : "[data-region=rule]"
        action : "[data-region=action]"

      regions:
        rule   : "@ui.rule"
        action : "@ui.action"

      onShow: ->
        name = "Rule" + (@model.get('IS_SYSTEM') and "System" or "") + helpers.camelCase(@options.type, true)

        if cl = App.Views.Policy.Sidebar[name]
          @rule.show new cl
            model : @model.get 'DATA'
            save  : @ui.save

          @listenTo @rule.currentView, "form:changed", @onChangeForm
          @listenTo @rule.currentView, "form:reset", @onChangeForm

        @action.show new App.Views.Policy.Sidebar.Action
          model : @model
          save  : @ui.save
          type  : @options.type

        @listenTo @action.currentView, "form:changed", @onChangeForm
        @listenTo @action.currentView, "form:reset", @onChangeForm

      onChangeForm: ->
        enabled = @action.currentView.isChanged
        enabled = @rule.currentView.isChanged if @rule.currentView and not enabled
        @ui.save.prop "disabled", not enabled

      save: (e) ->
        type = $(e.currentTarget).data 'type'
        data = @rule.currentView?.get()

        if data
          modelData = @model.get 'DATA'
          modelData.set data, validate: true

          return if modelData.validationError

        actions = if type is 'reset' then @action.currentView.defaults() else @action.currentView.get()
        @model.setActions actions

        @model.save null,
          wait: true
          success : =>
            @collection = @model.getActions()
            Module.trigger "policy:back:policy", @

        @ui.save.prop "disabled", true

      del: -> Module.trigger "policy:item:delete", @, "Rule"

      isChanged: (view) ->
        return true if @action.currentView.isChanged
        return true if @rule.currentView?.isChanged
        false

      back: (e) ->
        e?.preventDefault()

        if @model.isNew()
          if @isChanged()
            @del()
          else
            Module.trigger "policy:back:policy", @
            @model.destroy()
        else
          if @isChanged()
            App.Helpers.confirm
              title   : App.t 'global.attention'
              data    : App.t 'global.not_saved'
              accept  : => Module.trigger "policy:back:policy", @
          else
            Module.trigger "policy:back:policy", @
