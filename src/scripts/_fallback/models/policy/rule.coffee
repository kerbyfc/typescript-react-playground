"use strict"

helpers = require "common/helpers.coffee"

App.module "Policy",
  startWithParent: false
  define: (Module, App) ->

    App.Models.Policy ?= {}

    class App.Models.Policy.ActionItem extends Backbone.Model

      idAttribute: "POLICY_ACTION_ID"

      urlRoot: "#{App.Config.server}/api/policyAction"

      defaults: ->
        DATA: {}
        TYPE: ""

      getPolicy: -> @getRule().getPolicy()

      getRule: -> @collection._rule

    class App.Models.Policy.Action extends Backbone.Collection

      model: App.Models.Policy.ActionItem

      url: "#{App.Config.server}/api/policyAction"

      islock: (data) ->
        data = 'edit_action' if data is 'edit'
        @getPolicy().islock data

      getPolicy: -> @getRule().getPolicy()

      getRule: -> @_rule

    class App.Models.Policy.RuleDataItem extends Backbone.Model

      islock: (data) ->
        data = 'edit_rule' if data is 'edit'
        @getPolicy().islock data

    class App.Models.Policy.RuleDataTransfer extends App.Models.Policy.RuleDataItem
      defaults: ->
        DIRECTION        : "0"
        OBJECT_TYPE_CODE : null
        CONDITION_SOURCE : "0"
        CONDITION_DEST   : "0"
        SOURCE           : null
        DEST             : null
        START_TIME       : null
        END_TIME         : null
        DAY              : null
        WORKSTATION      : null

    class App.Models.Policy.RuleDataCopy extends App.Models.Policy.RuleDataItem
      defaults: ->
        SOURCE           : null
        CONDITION_SOURCE : "0"
        OBJECT_TYPE_CODE : null
        START_TIME       : null
        END_TIME         : null
        DAY              : null
        WORKSTATION      : null

    class App.Models.Policy.RuleDataPlacement extends App.Models.Policy.RuleDataItem
      defaults: ->
        CONDITION_SOURCE      : "0"
        CONDITION_DEST        : "0"
        CONDITION_WORKSTATION : "0"
        OBJECT_TYPE_CODE      : null
        OWNER                 : null
        SOURCE                : null
        DEST                  : null
        WORKSTATION           : null

    class App.Models.Policy.RuleDataPerson extends App.Models.Policy.RuleDataItem
      defaults: ->
        VIOLATION : null
        POLICY    : null

    class App.Models.Policy.RuleItem extends Backbone.Model

      idAttribute: "POLICY_RULE_ID"

      urlRoot: "#{App.Config.server}/api/policyRule"

      type: 'rule'

      defaults: ->
        TYPE      : ""
        IS_SYSTEM : 0
        POLICY_ID : 0
        actions   : []
        DATA      : {}

      islock: (data) ->
        data = 'edit_rule' if data is 'edit'
        @getPolicy().islock data

      initialize: (o) ->
        @setModels @attributes

      setModels: (data) ->
        data.actions = new App.Models.Policy.Action data.actions
        data.actions._rule = @

        policyClassName = "RuleData#{_.capitalize(@attributes.TYPE)}"
        data.DATA = new App.Models.Policy[policyClassName] data.DATA
        data.DATA.getPolicy = => @getPolicy()

        data.DATA.on "change", (model) =>
          @changed ?= {}
          @changed.DATA = model.changed

        data

      setActions: (data) ->
        actions = @getActions()

        for type of data
          action = actions.where TYPE: type

          if not data[type]
            if action.length
              actions.remove action[0]
              @changed.actions = true
          else
            if action.length
              o = DATA: VALUE: data[type]
              if not _.isEqual action[0].get('DATA'), o.DATA
                action[0].set o
                @changed.actions = true
            else
              actions.add
                TYPE: type
                DATA: VALUE: data[type]
              @changed.actions = true

      toJSON: (res) ->
        data = super
        data.DATA = data.DATA.toJSON()
        data.actions = data.actions.toJSON()
        data

      parse: (res) -> @setModels res.data

      getPolicy: -> @collection._policy

      getActions: -> @get 'actions'

    class App.Models.Policy.Rule extends Backbone.Collection

      model: App.Models.Policy.RuleItem

      url: "#{App.Config.server}/api/policyRule"
