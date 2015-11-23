"use strict"

style = require "common/style.coffee"

App.module "Policy",
  startWithParent: false

  define: (Module, App) ->

    App.Views.Policy ?= {}
    App.Views.Policy.Sidebar ?= {}

    class App.Views.Policy.Sidebar.RuleCopy extends Marionette.ItemView

      template: 'policy/sidebar/rule/copy'

      templateHelpers: ->
        type    : @model.get 'TYPE'
        day     : -> App.t 'daterangepicker.daysOfWeekFull', returnObjectTrees: true

        channel : ->
          services = App.request("bookworm", "service").toJSON()

          services = _.filter services, (item) ->
            return true if item.mnemo in [ "file", "print", "multimedia" ]
            false

          _.sortBy services, 'name'

      ui: DAY: "[name=DAY]"

      behaviors: ->
        Form:
          listen : @options.model
          submit : @options.save
          syphon : @options.model.toJSON()

      onShow: ->
        @ui.DAY
        .multiselect
          buttonContainer : '<div class="policyControl__multiselect">'
          buttonTitle   : -> ""
          buttonText    : (options) ->
            if options.length is 0
              return App.t('daterangepicker.anyDayOfWeek')
            else
              selected = ''
              options.each ->
                label = if ($(@).attr('label') isnt undefined) then $(@).attr('label') else $(@).text()
                selected += label + ', '

              return selected.substr(0, selected.length - 2)

        _.each @model.get('DAY'), (item) => @ui.DAY.multiselect 'select', item

      get: ->
        data = @getData()

        data.DAY = null if not data.DAY?.length

        if data.START_TIME is data.END_TIME
          data.START_TIME = null
          data.END_TIME = null
        data
