"use strict"

helpers = require "common/helpers.coffee"
entry = require "common/entry.coffee"
style = require "common/style.coffee"
require "common/backbone-paginator.coffee"
require "models/policy/rule.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Policy ?= {}

    class App.Models.Policy.PolicyItem extends App.Common.ValidationModel

      idAttribute: "POLICY_ID"

      urlRoot: "#{App.Config.server}/api/policy"

      type: 'policy'

      defaults: ->
        DISPLAY_NAME : ""
        STATUS       : 1
        USER_ID      : 0
        START_DATE   : null
        END_DATE     : null
        NOTE         : ""
        CREATE_DATE  : ""
        CHANGE_DATE  : ""
        TYPE         : ""
        rules        : []
        DATA         :
          ITEMS  : []

      getCurrentObjectTypes: ->
        _.uniq _.pluck(@getObjects(), "TYPE")

      getPolicyType: (type) ->
        switch type
          when "catalog", "document", "filetype", "fileformat"
            return "OBJECT"
          when "person", "group", "status"
            return "PERSON"

      getObjectTypes: (type) ->
        type = type or @get 'TYPE'
        switch type
          when "OBJECT" then ["catalog", "document", "file"]
          when "PERSON" then ["person", "group", "status"]
          else null

      getRuleTypes: ->
        switch @get 'TYPE'
          when "OBJECT"
            product = App.Setting.get 'product'
            return ["transfer", "copy"] if product is "pdp"
            ["transfer", "copy", "placement"]
          when "PERSON" then ["person"]
          else null

      getNewPolicyName: (type) ->
        name = App.t "entry.policy.#{type}"
        i = 0
        while @collection.where(DISPLAY_NAME: name).length
          name = App.t("entry.policy.#{type}") + " #" + ( ++i + 1 )
        name

      validation:
        DISPLAY_NAME: [
          required : true
        ,
          rangeLength : [1, 256]
        ,
          not_unique_field: true
          fn: (value, attr, model) ->
            (o = {})[attr] = value
            policy = @collection.where o

            if policy.length and @ isnt policy[0]
              return App.t 'form.error.not_unique_field'
        ]
        NOTE: [
          required  : false
        ,
          rangeLength : [0, 1000]
        ]

      initialize: (o, objects) ->
        objects = @attributes.DATA.ITEMS
        if @isNew()
          objects = @attributes.DATA.ITEMS
          type  = @attributes.TYPE
          unless type
            if objects.length
              type = @getPolicyType objects[0].TYPE
            else type = "OBJECT"

            @attributes.TYPE = type

          @attributes[@nameAttribute] = @getNewPolicyName type unless @attributes[@nameAttribute]

        @fixed @attributes

        @setSystemRules() if @isNew()

      deserialize: ->
        data = super true
        delete data.rules
        data

      toJSON: (withContent) ->
        data = super true
        delete data.DATA.relation if data.DATA?.relation

        data.DATA = _.cloneDeep data.DATA

        if data.DATA?.ITEMS?
          _.each data.DATA.ITEMS, (item) ->
            delete item.isDeleted
            delete item.content if not withContent and item.content

        data.rules = data.rules.toJSON()
        data

      isDeletedObject: ->
        deleted = 0
        _.each @getObjects(), (item) ->
          deleted++ if entry.isDeleted item
        return true if deleted
        false

      validate: (attrs) ->
        err = super

        if @get('TYPE') is 'PERSON' and attrs.DATA?.ITEMS?.length is 0
          err ?= {}
          err.misc = [ 'entry.policy.empty_entry_error' ]
        err

      save: (data, options) ->
        data ?= {}
        DATA = @get "DATA"

        objects = data.DATA?.ITEMS
        objects = @getObjects() unless objects

        if objects

          _.each objects, (item) ->
            delete item.content if item.content

          objects = _.map objects, (item) ->
            item unless entry.isDeleted item

          data.DATA ?= {}
          data.DATA.ITEMS = _.compact objects

        super data, options

      parse: (res) ->
        data = super
        if data.DATA?.ITEMS?
          _.each data.DATA.ITEMS, (item) ->
            item.TYPE = item.TYPE.toLowerCase()
            delete item.content if item.content

        @fixed data

      fixed: (attrs) ->
        if attrs.START_DATE and not _.isString attrs.START_DATE
          attrs.START_DATE = attrs.START_DATE.format style.formatTime

        if attrs.END_DATE and not _.isString attrs.END_DATE
          attrs.END_DATE = attrs.END_DATE.format style.formatTime

        if _.isArray attrs.rules
          attrs.rules = new App.Models.Policy.Rule attrs.rules
          attrs.rules._policy = @

        if not attrs.USER_ID
          attrs.USER_ID = +App.Session.currentUser().get('USER_ID')
        attrs

      getObjects: -> @get('DATA').ITEMS

      getRules: (type) ->
        rules = @get 'rules'
        return rules if not type

        new Backbone.Collection rules.where TYPE: type

      setSystemRules: ->
        switch @get 'TYPE'
          when "OBJECT"
            system = _.map @getRuleTypes(), (item) ->
              TYPE: item
              IS_SYSTEM: 1
            @attributes.rules.add system

      getPolicy: -> @

      islock: (data) ->
        data = action: data if _.isString data
        data.type = "policy_#{@get('TYPE').toLowerCase()}"
        super data

    class App.Models.Policy.Policy extends Backbone.Collection

      model: App.Models.Policy.PolicyItem

      types: ->
        _.filter [
          "OBJECT"
          "PERSON"
        ], (item) -> helpers.can type: "policy_#{item.toLowerCase()}"

      url: "#{App.Config.server}/api/policy?sort[CREATE_DATE]=asc"

      initialize: ->
        @listenTo @, "sync", (o) ->
          entry.add o.models or o.attributes

        @listenTo @, "reset", (model) ->
          entry.clear "policy"

      addEntry: (o) ->
        if _.isArray o
          for i in o
            @addEntry i
          return

        if o.content
          if o.isDeleted
            entry.addDeleted o.TYPE, o.ID

          entry.add o.content
          delete o.content
        else
          entry.addDeleted o.TYPE, o.ID if o.ID isnt o.NAME

      parse: (res) ->
        return res if res.cid
        res = super res

        res = _.filter res, (item) ->
          return true if helpers.can type: "policy_#{item.TYPE.toLowerCase()}"
          false

        for i of res
          model = res[i]

          m = model.DATA?.ITEMS

          @addEntry m if m?.length

          if model.rules.length
            data = _.pluck model.rules, 'DATA'

            for k in data
              delete k.indexItem
              @addEntry k.WORKSTATION if k.WORKSTATION
              @addEntry k.OWNER if k.OWNER
              @addEntry k.SOURCE if k.SOURCE
              @addEntry k.DEST if k.DEST

            actions = _.pluck model.rules, 'actions'

            for k in actions
              elements = _.find k, TYPE: 'TAG'
              elements = _.find k, TYPE: 'ADD_PERSON_STATUS' unless elements

              @addEntry elements.DATA.VALUE if elements?.DATA?.VALUE

        res

    class App.Models.Policy.QueryList extends App.Common.BackbonePagination

      model: Backbone.Model

      paginator_core:
        # TODO: выпилить;
        url: ->
          url = "#{App.Config.server}/api/search?type=query&scopes=policy&start=#{@currentPage * @perPage}&limit=#{@perPage}"
          if @filter
            url += "&" + $.param(@filter)
          if @sortRule
            url += "&" + $.param(@sortRule)
          if @config
            url += "&" + $.param(@config)

          return url
        dataType: "json"

      parse: (res) ->
        super
        res.data.policy
