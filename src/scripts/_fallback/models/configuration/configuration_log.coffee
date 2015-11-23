"use strict"

App.module "Configuration",
  startWithParent: false
  define: (Configuration, App, Backbone, Marionette, $) ->

    App.Models.Configuration ?= {}

    class App.Models.Configuration.ConfigurationLog extends Backbone.Collection

      model: Backbone.Model

      url: "#{App.Config.server}/api/configLog"

      parse: (data) ->
        data = super data
        @_filterEmpty data

      ##########################################################################
      # PRIVATE

      ###*
       * Filters added elements' emtpy keys
       * @param {Object} data - incoming data
       * @return {Object} data stripped of empty keys(mutated)
      ###
      _filterEmpty: (data) ->
        data.map (elem) ->
          ownKeys = elem.FIELDS[elem.ENTITY]

          if ownKeys
            for own key, val of ownKeys
              if _.isNull val
                delete elem.FIELDS[elem.ENTITY][key]

          elem
