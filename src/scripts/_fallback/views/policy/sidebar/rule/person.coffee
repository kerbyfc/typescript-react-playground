"use strict"

select2 = require "common/select2.coffee"
style = require "common/style.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.RulePerson extends Marionette.ItemView

      template: 'policy/sidebar/rule/person'

      templateHelpers: -> type: @model.get 'TYPE'

      ui:
        VIOLATION : "[name=VIOLATION]"
        POLICY    : "[name=POLICY]"

      behaviors: ->
        data = @options.model.toJSON()
        data.POLICY = select2.setVal data.POLICY

        Form:
          submit         : @options.save
          syphon         : data
          select         : []
          customDisabled : @ui.POLICY
          listen         : @options.model

      onShow: ->
        self = @

        select2.set @ui.POLICY,
          local              : null
          server             : null
          minimumInputLength : 0

          query : (query) ->
            data = results: []
            Module.controller.collection.each (model) ->
              return if model.id is self.model.getPolicy().id
              return if model.get('TYPE') is 'PERSON'
              if query.term.length is 0 or model.getName().toUpperCase().indexOf(query.term.toUpperCase()) >= 0
                data.results.push
                  ID   : model.id
                  NAME : model.getName()
                  TYPE : "policy"

            query.callback data

        format = (e) ->
          className = style.className.action.VIOLATION
          "<i class='policyControl__threat #{className}' data-threat=#{e.id.toLowerCase()}></i>#{e.text}"

        @ui.VIOLATION.select2
          width         : 'element'
          minimumResultsForSearch : 100
          formatResult      : format
          formatSelection     : format

      get: ->
        data = @getData()

        data.POLICY = if data.POLICY then select2.getVal data.POLICY, true else null
        data
