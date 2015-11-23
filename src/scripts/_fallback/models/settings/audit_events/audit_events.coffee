"use strict"

require "common/backbone-parse-model.coffee"

App.module "Settings.AuditEvents",
  define: (AuditEvents, App, Backbone, Marionette, $) ->

    App.Models.AuditEvents ?= {}

    class App.Models.AuditEvents.Model extends App.Common.NestedModelParser

      idAttribute: "AUDIT_LOG_ID"

      parse: (data) ->
        super data
        changes = data.PROPERTY_CHANGES

        @_parseKeys changes

        if (_.isObject changes?.old) and (_.isObject changes?.new)
          @_diffChanges.call @, changes

        else if (_.isObject changes?.new)
          @_filterEmpty changes.new

        if (changes?.new is "") and (_.isObject changes?.old)
          @_fallbackStructure changes

        data

      ##########################################################################
      # PROTECTED

      _systemKeys = [
        "IS_SYSTEM"
        "VISIBILITY_AREA_ID"
        "object_header"
        "USER_TYPE"
        "PROVIDER"
        "EDITABLE"
        "RECEIVE_NOTIFICATION"
        "HIDE_OBJECT_CONTENT"
        "USER_ID"
        "ROLE_ID"
        "ROLE_TYPE"
        "NAME"
      ]

      _specialKeys =
        "STATUS":
          0 : "status_active"
          1 : "status_unactive"

      ##########################################################################
      # PRIVATE

      _getMutators: ->
        privileges : @_parsePrivileges
        STATUS     : @_parseStatus

      ###*
       * Deletes system keys and parses special keys
       * @param {Object} changes - Data that contains audited property changes
      ###
      _parseKeys: (changes) ->

        for own groupKey, propGroup of changes
          for own propKey, prop of propGroup

            # Delete System keys
            if (propKey in _systemKeys) or prop?.expression
              delete propGroup[propKey]

            # Apply mutations
            if mutator = @_getMutators()[propKey]
              propGroup[propKey] = mutator(prop)

      ###*
       * Changes slash notation to snake case
       * @param {Array} privileges - array of objects
       * @return {Array} array of {NAME}
      ###
      _parsePrivileges: (privileges) =>
        privileges.map (privilege) =>
          'NAME' : @t "priviledge.#{privilege.PRIVILEGE_CODE.replace(/[\/:]/g, '_')}"

      ###*
       * Parses 0 and 1 statuses into strings
       * @param {Number} status
       * @return {String} parsed status
      ###
      _parseStatus: (status) ->
        if status is 1 then "status_active" else "status_unactive"

      ###*
       * Compares property changes and removes those with equal values
       * @param {Object} changes - Data that contains audited property changes
      ###
      _diffChanges: (changes) ->
        for own key, newProp of changes.new
          oldProp = changes.old[key]

          # Removes identical fields in old and new
          if oldProp and (_.isEqual oldProp, newProp)
            delete changes.old[key]
            delete changes.new[key]

          # Colors added/removed values
          else if (_.isArray newProp) and (_.isArray oldProp)
            for addedElem in @_deepDifference newProp, oldProp
              addedElem[@PROP_COLOR] = 'bg-success'

            for removedElem in @_deepDifference oldProp, newProp
              removedElem[@PROP_COLOR] = 'bg-danger'

      ###*
       * Returns arrays difference (first minus second)
       * @param {Array} main - Minuend, array of objects
       * @param {Array} removalArray - Subtrahend, array of objects
       * @return {Array} Result, array of objects
      ###
      _deepDifference: (main, removalArray) ->
        filtered = []

        for value, index in main
          filtered.push value

          for removal in removalArray
            if _.isEqual value, removal
              filtered.splice index, 1

        filtered

      ###*
       * Filters null and empty string property value
       * @param {Object} newProps - Property group
      ###
      _filterEmpty: (newProps) ->
        for own key, val of newProps
          if val is "" or val is null
            delete newProps[key]

      _fallbackStructure: (changes) ->
        changes.new = {}

        for own key of changes.old
          changes.new[key] = null

      ##########################################################################
      # PUBLIC

      ###*
       * Returns key for iterating over several property change groups
       * @return {String} Base iteration object name
      ###
      getBaseKey: ->
        changes = @get 'PROPERTY_CHANGES'

        # Get keys if exist in a particular order
        _.first _.keys _.pick(changes, "request", "new", "old")

      ###*
       * @return {Array} Changed property gathered from all property change groups
      ###
      getChangedVals: (changedkey) ->
        changes = @get 'PROPERTY_CHANGES'
        changedVals = []

        for own key, val of changes
          changedVals.push val[changedkey]

        changedVals

      ###*
       * @return {Int} Number of property change groups
      ###
      countKeys: ->
        return Object.keys(@get 'PROPERTY_CHANGES').length


    class App.Models.AuditEvents.Collection extends Backbone.Collection

      model : App.Models.AuditEvents.Model

      url   : "#{App.Config.server}/api/auditLog"

      initialize: ->
        @listenTo AuditEvents, "fetch:audit:events", @_fetchAuditEvents

      ##########################################################################
      # PRIVATE

      _fetchAuditEvents: (extra) ->
        @fetch(
          _.merge
            data:
              filter : AuditEvents.reqres.request "get:fetch:filters"
              limit  : 20
              sort   : AuditEvents.reqres.request "get:sort:options"
          ,
            extra
        )
