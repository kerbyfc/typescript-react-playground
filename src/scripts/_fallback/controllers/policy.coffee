"use strict"

helpers = require "common/helpers.coffee"
entry = require "common/entry.coffee"
style = require "common/style.coffee"

require "models/policy/policy.coffee"

require "views/controls/list.coffee"
require "views/controls/tree.coffee"
require "views/controls/dialog.coffee"

require "views/policy/content.coffee"
require "views/policy/sidebar/empty.coffee"
require "views/policy/sidebar/action.coffee"
require "views/policy/sidebar/policy.coffee"
require "views/policy/sidebar/filter.coffee"
require "views/policy/sidebar/objects.coffee"
require "views/policy/sidebar/rule.coffee"
require "views/policy/sidebar/rule/transfer.coffee"
require "views/policy/sidebar/rule/copy.coffee"
require "views/policy/sidebar/rule/placement.coffee"
require "views/policy/sidebar/rule/person.coffee"

require "controllers/configuration.coffee"

require "behaviors/common/role.coffee"
require "behaviors/common/form.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    class Controller extends Marionette.Controller

      events:
        "rule:add:after": (model) ->
          view = @getView model
          view.selected = false

          Module.trigger "policy:item:select", view, "Rule"

        "policy:sidebar:add:rule": (model, type) ->
          policyModel = model.getPolicy()

          policyView = @getView policyModel
          policyView.open type

          (o = TYPE: type)[policyModel.idAttribute] = policyModel.id

          ruleModel = new App.Models.Policy.RuleItem o

          model.getRules().once "add", =>
            ruleView = @getView ruleModel

            ruleView.selected = false
            Module.trigger "policy:item:select", ruleView, "Rule"

          model.getRules().add ruleModel

        "policy:view:init": (view) ->
          @_models.push view.model
          @_views.push  view

        "policy:filter:apply": (view) ->
          # TODO: рефакторить фильтр;
          data = Module.filter

          @content.$el
          .find style.selector.filtered
          .removeClass style.className.filtered

          @content.$el.find('.policyFilter__item').remove()
          if data and (data.name?.length or data.object?.length)
            @content.children.each (policy) ->
              policy.$el.hide()

            @content.ui.listFilter.show()
          else
            @content.children.each (policy) ->
              policy.$el.show()
            @content.ui.listFilter.hide()

            Module.trigger "policy:sidebar:filter", @content
            return

          tpl = """<span class='policyFilter__item'>__policy__: __name__
            <span data-id='__id__' data-type='__type__' data-action=removeFilter class='policyFilter__deleteItem'>
            </span>
          </span>"""

          objects = _.map data.object, (item) -> item.TYPE + ":" + item.ID
          if data?.object?.length
            _.each data.object, (object) =>
              select = @content.$el.find('[data-type='+object.TYPE+'][data-id="'+object.ID+'"]')

              @content.ui.listFilter.prepend(
                tpl
                .replace "__policy__", App.t "select_dialog.#{object.TYPE}"
                .replace "__name__", object.NAME
                .replace "__id__", object.ID
                .replace "__type__", object.TYPE
              )

              if select?.length
                select.addClass(style.className.filtered).closest('.policy').show()

          @content.children.each (policy) =>
            select = _.where data.name, ID: policy.model.id

            policyObjects = policy.model.getObjects()
            policyObjects = _.map policyObjects, (item) -> item.TYPE + ":" + item.ID

            if _.intersection(objects, policyObjects).length
              policy.$el.show()
            if select?.length
              @content.ui.listFilter.prepend(
                tpl
                .replace "__policy__", App.t 'global.NAME'
                .replace "__name__", policy.model.getName()
                .replace "__id__", policy.model.id
                .replace "__type__", "policy"
              )
              policy.$el.show()
              policy.$el.find(".policy__name").addClass(style.className.filtered)

        "policy:filter:reset": (type, data) ->
          Module.filter = null
          Module.trigger "policy:filter:apply"

        "policy:item:select": (view, type) ->
          view = @getView view if view instanceof Backbone.Model
          Module.trigger "policy:item:clear:select"

          switch type
            when "Content"
              App.Layouts.Application.sidebar.show new App.Views.Policy.Empty
            else
              view.$el.addClass style.className.selected
              view.selected = true
              App.Layouts.Application.sidebar.show new App.Views.Policy.Sidebar[type]
                model : view.model
                type  : view.type

        "policy:back:policy": (view) ->
          model = view.model.getPolicy()
          view  = @getView model
          Module.trigger "policy:item:select", view, "Policy"

        "policy:sidebar:filter": (view) ->
          Module.trigger "policy:item:clear:select"
          App.Layouts.Application.sidebar.show new App.Views.Policy.Sidebar.Filter
            data     : Module.filter
            collection : @collection

        "policy:item:delete": (view, type) ->
          model = view.model

          App.modal.show new App.Views.Controls.DialogDelete
            selected : [ model ]
            type   : model.type
            action   : "delete"
            callback : ->
              if type is "Policy"
                Module.trigger "policy:item:select", view, "Content"
              else
                Module.trigger "policy:back:policy", view

              model.destroy()

              App.modal.empty()

      getView: (model) ->
        index = @_models.indexOf model
        if index isnt -1 then @_views[index] else null

      initialize: ->
        @_models = []
        @_views  = []

        app = App.Layouts.Application

        Marionette.bindEntityEvents @, Module, @events

        @collection = new App.Models.Policy.Policy

        @listenTo App.Configuration, "configuration:rollback", =>
          App.Layouts.Application.sidebar.show new App.Views.Policy.Empty
          @collection.fetch reset: true
          @content.render()

        $.ajax
          url    : "#{App.Config.server}/api/ldapStatus?limit=1000&filter[EDITABLE]=1"
          dataType : 'json'
        .done (data) ->
          entry.clear 'status'
          entry.add data.data

        @content = new App.Views.Policy.Content collection: @collection

        App.Layouts.Application.content.show new App.Views.Policy.ContentEmpty
        App.Layouts.Application.sidebar.show new App.Views.Policy.Empty

        App.Layouts.Application.sidebar.$el?.parent()
        .removeClass style.className.positionLeft
        .addClass style.className.positionRight

        @collection.fetch
          silent  : true
          success : => @_fetch()
          error   : (collection, xhr) ->
            return if xhr.statusText is 'abort'

            App.Notifier.showError
              hide  : true
              title : App.t "select_dialog.policy", context: "many"
              text  : App.t "not_load",
                postProcess : "entry"
                entry   : "policy"
                context   : "error"

      _fetch: ->
        App.Layouts.Application.content.show @content

        if Module.createPolicy
          @collection.create DATA: ITEMS: Module.createPolicy,
            wait: true
            success: (model) =>
              Module.filter =
                name: [
                  ID   : model.id
                  NAME : model.getName()
                  TYPE : "policy"
                ]
              view = @getView model

              Module.trigger "policy:filter:apply"
              Module.trigger "policy:item:select", view, "Policy"
          return

        if Module.filter?.name?.length is 1
          id     = Module.filter.name[0].ID
          policy = @collection.get id

          unless policy
            App.Notifier.showError
              hide  : true
              title : App.t "select_dialog.policy", context: "many"
              text  : App.t "not_found",
                postProcess : "entry"
                entry   : "policy"
                context   : "error"
            return

          Module.filter.name = [
            ID   : id
            NAME : policy.getName()
            TYPE : "policy"
          ]

          Module.trigger "policy:filter:apply"

          view = @getView policy

          Module.trigger "policy:item:select", view, "Policy"

    # Initializers And Finalizers
    # ---------------------------
    Module.addInitializer ->
      @controller = new Controller
      @filter ?= {}
      App.Configuration.show()

    Module.addFinalizer ->
      @controller.destroy()

      delete @controller
      delete @filter
      delete @createPolicy

      App.Configuration.hide()

      App.Layouts.Application.sidebar.$el?.parent()
      .addClass style.className.positionLeft
      .removeClass style.className.positionRight
