"use strict"

style = require "common/style.coffee"
entry = require "common/entry.coffee"

App.module "Policy",

  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.Action extends Marionette.ItemView

      getTemplate: ->
        "policy/sidebar/action/#{@options.type}"

      templateHelpers: ->
        isStatuses : -> entry.get('status').length
        statuses   : -> entry.get('status')

      ui:
        ACTION            : "[name=ACTION]"
        VIOLATION         : "[name=VIOLATION]"
        ADD_PERSON_STATUS : "[name=ADD_PERSON_STATUS]"
        actions           : "[data-ui=actions]"

      defaults: ->
        NOTIFY_SENDER     : ""
        NOTIFY            : null
        ADD_PERSON_STATUS : ""
        VIOLATION         : if @options.model.get('IS_SYSTEM') then null else "NO"
        TAG               : ""
        DELETE            : ""
        ACTION            : null

      behaviors: ->
        model = @options.model
        data = _.result @, 'defaults'

        model.getActions().each (action) ->
          value = action.get('DATA')?.VALUE
          value = value[0].ID if action.get('TYPE') is 'ADD_PERSON_STATUS'
          data[action.get('TYPE')] = value

        Form:
          listen : model.get('actions')
          syphon : data
          submit : @options.save
          select : []

      onChangeForm: ->
        return if @model.islock 'edit_action'
        isHidden = @serialize().DELETE

        @ui.actions[if isHidden then 'hide' else 'show']()

      onShow: ->
        @listenTo @, "form:change", @onChangeForm
        @listenTo @, "form:reset", @onChangeForm

        format1 = (e) ->
          "<i class='"+style.className.action[e.id or "apply"]+"'></i>"+e.text+""

        @ui.ACTION.select2
          minimumResultsForSearch : 100
          formatResult            : format1
          formatSelection         : format1

        format2 = (e) ->
          className = style.className.action.VIOLATION
          "<i class='policyControl__threat #{className}' data-threat="+e.id.toLowerCase()+"></i>"+e.text+""

        @ui.VIOLATION.select2
          minimumResultsForSearch : 100
          formatResult            : format2
          formatSelection         : format2

        @ui.ADD_PERSON_STATUS.select2 allowClear: true

        @onChangeForm()

      serialize: ->
        data = super
        if value = data.DELETE
          data = _.extend super, _.result(@, 'defaults')
          data.VIOLATION = null
          data.DELETE = value
        data

      get: ->
        data = @serialize()
        if id = data.ADD_PERSON_STATUS
          _data =
            TYPE : 'status'
            ID   : id

          name = entry.getName _data
          data.ADD_PERSON_STATUS = [ _.extend(_data, NAME: name) ]
        data
