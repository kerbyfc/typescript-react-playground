"use strict"

async = require "async"
helpers = require "common/helpers.coffee"
require "common/backbone-validation.coffee"
require "common/backbone-paginator.coffee"
require "models/analysis/table.coffee"
require "views/controls/dialog.coffee"

App.module "Protected",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Protected ?= {}

    class App.Models.Protected.DocumentConditionEntryItem extends App.Common.ValidationModel

      idAttribute: "ENTRY_ID"

    class App.Models.Protected.DocumentConditionItem extends App.Common.ValidationModel

      idAttribute: "CONDITION_ID"

      defaults: entries: []

      toJSON: ->
        data = super
        data.entries = data.entries.toJSON arguments...
        data

      set: ->
        res = super
        if @attributes.entries and _.isArray(@attributes.entries)
          @attributes.entries = new App.Models.Protected.DocumentConditionEntry @attributes.entries
        res

    class App.Models.Protected.DocumentItem extends App.Common.BackbonePaginationItem

      idAttribute: "DOCUMENT_ID"

      model2sectionAttribute: 'document2catalog'

      type: 'document'

      urlRoot: "#{App.Config.server}/api/protectedDocument"

      defaults:
        DISPLAY_NAME : ""
        NOTE         : ""
        conditions   : []
        entries_pool : []

      collections: ->
        _.extend
          entries_pool : App.Models.Protected.DocumentConditionEntry
          conditions   : App.Models.Protected.DocumentCondition
        , super

      deserialize: ->
        data = super true
        data.entries_pool = new App.Models.Protected.DocumentConditionEntry data.entries_pool
        data.conditions = new App.Models.Protected.DocumentCondition data.conditions
        data.entries_pool.section = @
        data.conditions.section = @

        section = @collection.section
        d2c     = @get('document2catalog').get section.id
        data.ENABLED = if +section.get 'ENABLED' then d2c.get 'ENABLED' else 0
        data

      islock: (original) ->
        data = action: original if _.isString original

        if data.action is 'move'
          if _islock = helpers.islock {
            type   : 'catalog'
            action : 'edit'
          }
            return _islock
        super data, original

      toJSON: (withContent) ->
        data = super
        if not withContent
          _.each data.entries_pool.concat(data.conditions), (item) ->
            delete item.content if item.content
        data

      isEnabled: ->
        section = @collection.section
        catalog = @getModel2Section().get section.id
        return false unless catalog
        catalog.isEnabled()

      getDefaultCondition: (data, single) ->
        type = data.TYPE or data.ENTRY_TYPE
        type = 'fingerprint' if type is 'graphic' or type is 'stamp'

        condition =
          ENTRY_TYPE : type
          ENTRY_ID   : data.ID or data.ENTRY_ID
          content    : data.content

        switch type
          when "text_object"
            condition.QUANTITY_THRESHOLD = 1
            conditions = [ entries: [ condition ] ]
          when "form"
            condition.QUANTITY_THRESHOLD = 3
            condition.DETECT_FILLED_FORM = 1
            conditions = [ entries: [ condition ] ]
          when "table"
            if single
              _.extend condition, FINGERPRINT_CONDITION_ID: data.content.conditions[0].CONDITION_ID
            else
              conditions = _.map data.content.conditions, (item) ->
                entries: [ _.extend(FINGERPRINT_CONDITION_ID: item.CONDITION_ID, condition) ]
          else conditions = [ entries: [ condition ] ]

        if single then condition else conditions

      create: (data) ->
        # TODO: в дальнейшем необходимо порефакторить создание ОЗ
        # вынести на уровень коллекций условий и сущностей
        create_elementary = data[1]
        data       = data[0]
        catalog    = @collection.section
        collection = @collection
        section    = collection.section

        fetch = _.throttle collection.fetch, collection.timeoutAutoRefresh

        if create_elementary
          countError = 0
          async.eachSeries data, (options, callback) =>
            type = options.TYPE
            type = 'fingerprint' if type is 'graphic' or type is 'stamp'

            conditions = @getDefaultCondition options

            model = new @collection.model
              DISPLAY_NAME: App.t("select_dialog.#{options.TYPE}") + ": " + options.NAME
              document2catalog: [
                ENABLED    : section.get 'ENABLED'
                CATALOG_ID : catalog.id
              ]
              entries_pool: [
                ENTRY_ID   : options.ID
                ENTRY_TYPE : type
              ]
              conditions: conditions
            ,
              collection : @collection
              parse      : true

            model.save null,
              wait: true
              success: (model) ->
                callback null, model
                fetch.apply collection

              error: (model) ->
                ++countError
                callback null, model

          , ->
            return unless countError
            objects = App.t "select_dialog.document", count: countError
            App.Notifier.showError
              title : App.t "select_dialog.document", context: "many"
              text  : App.t "entry.document.create_elementary",
                context : "error"
                count   : countError
                objects : objects.toLowerCase()
              hide  : true

          App.modal.empty()
          return

        entries_pool = []

        conditions = [ entries: [] ]

        for o in data
          type = o.TYPE
          type = 'fingerprint' if type is 'graphic' or type is 'stamp'

          entry =
            ENTRY_ID   : o.ID
            ENTRY_TYPE : type
            content    : o.content

          entries_pool.push entry

        model = new @collection.model
          document2catalog: [
            ENABLED    : section.get 'ENABLED'
            CATALOG_ID : catalog.id
          ]
          entries_pool : entries_pool
          conditions   : conditions
        ,
          collection : @collection
          parse      : true

        App.modal.empty()

        App.modal.show new App.Views.Protected.DocumentEdit
          model   : model
          section : catalog
          action  : "create"
          type    : 'document'
          size    : 'medium'

          callback : (data, type) =>
            model.save data,
              wait: true
              success: (model, response, options) =>
                @collection.fetch()
                App.modal.empty()

      validation:
        DISPLAY_NAME: [
          required : true
        ,
          rangeLength : [1, 256]
        ]
        NOTE: [
          required : false
        ,
          rangeLength : [0, 1000]
          msg         : App.t 'form.error.note_length'
        ]

      error: (err, models) ->
        return unless err
        error = {}

        if 'DISPLAY_NAME' of err
          error.DISPLAY_NAME = err.DISPLAY_NAME

        if 'CHECKSUM' of err
          model = models[0]
          section = @collection.section
          catalogs = _.map model.document2catalog, (link) ->
            catalog = section.collection.get link.CATALOG_ID
            catalog.getName()

          o =
            document : model.DISPLAY_NAME
            catalogs : catalogs.join ', '

          error.misc = [
            App.t 'protected.catalog.content_constraint_violation_error', o
          ]
        error

      validate: (data) ->
        error = super
        return error unless data

        unless data.entries_pool.length
          error ?= {}
          error.misc ?= []
          error.misc.push 'entry.document.missing_objects_error'

        unless data.conditions.length
          error ?= {}
          error.misc ?= []
          error.misc.push 'entry.document.missing_conditions_error'

        error

    class App.Models.Protected.DocumentCondition extends Backbone.Collection

      model: App.Models.Protected.DocumentConditionItem

    class App.Models.Protected.DocumentConditionEntry extends Backbone.Collection

      model: App.Models.Protected.DocumentConditionEntryItem

      toJSON: (withContent) ->
        data = super
        if not withContent
          _.each data, (item) ->
            delete item.content if item.content
        data

      setDataEntry: (data) ->
        _.map data, (item) =>

          switch item.TYPE
            when "graphic", "classifier", "stamp"
              type = "fingerprint"
            else
              type = item.TYPE

          o =
            ENTRY_ID   : item.ID
            ENTRY_TYPE : type

          entry = @section.get('entries_pool').findWhere o

          if entry
            entry = entry.toJSON true
          else
            entry = o
          _.extend entry, content: item.content

      getDataEntry: (data) ->
        data = @map (item) ->
          item.toJSON()

        _.map data, (item) ->
          switch item.content.TYPE
            when "homography", "classifier"
              type = "graphic"
            when "stamp"
              type = "stamp"
            else
              type = item.ENTRY_TYPE

          ID      : item.ENTRY_ID
          TYPE    : type
          NAME    : item.content.DISPLAY_NAME
          content : item.content

    class App.Models.Protected.Document extends App.Common.BackbonePagination

      model: App.Models.Protected.DocumentItem

      isLockEntries: ->
        entries = _.result @, 'entries'
        if entries.length
          false
        else
          App.entry.islock type: 'table'

      items: [
        "category"
        "text_object"
        "fingerprint"
        "form"
        "stamp"
        "table"
        "graphic"
      ]

      initialize: ->
        @entries = _.filter @items, (type) ->
          App.entry.can type: type

        super

      buttons: [ "create", "edit", "delete", "activate", "deactivate", "policy" ]

      islock: (original) ->
        data = action: original if _.isString original

        if not data.action or data.action is 'show'
          data =
            module : 'protected'
            action : 'show'

        if data.action is 'policy'
          data =
            type   : 'policy_object'
            action : 'edit'

        if data.action is 'move'
          if _islock = helpers.islock {
            type   : 'catalog'
            action : 'edit'
          }
            return _islock

        super data, original

      sortCollection: (args) ->
        args.field = 'document2catalog.ENABLED' if args.field is 'ENABLED'
        super

      toolbar: ->
        create: (selected) =>
          return [2, App.t("entry.document.#{islock.key}", context: 'error')] if islock = @isLockEntries()
          false

        activate: (selected) ->
          filtered = _.filter selected, (item) ->
            return true unless item.isEnabled()
            false

          return false if filtered.length
          true

        deactivate: (selected) ->
          filtered = _.filter selected, (item) ->
            return true if item.isEnabled()
            false

          return false if filtered.length
          true

      config: ->
        autosizeColumns : true
        draggable       : true
        default         : sortCol: "DISPLAY_NAME"

        columns : [
          id          : "ENABLED"
          name        : ""
          menuName    : App.t 'protected.document.status'
          field       : "ENABLED"
          width       : 32
          cssClass    : "center"
          resizable   : false
          sortable    : true
          formatter   : (row, cell, value, columnDef, dataContext) ->
            selected = dataContext.collection.section

            # Ищем связь с выбранным каталогом
            str = ""
            if selected
              d2c = dataContext.get('document2catalog').get selected.id

              str = if d2c and +d2c.get(columnDef.field) then "" else "in"
            "<span class='protected__itemIcon _#{str}active'></span>"
        ,
          id          : "DISPLAY_NAME"
          name        : App.t 'protected.document.display_name'
          field       : "DISPLAY_NAME"
          resizable   : true
          sortable    : true
          minWidth    : 200
          editor      : Slick.BackboneEditors.Text
          formatter   : (row, cell, value, columnDef, dataContext) ->
            """<span data-entry-id='#{dataContext.id}' data-entry-type='document' class='fontello-icon-info'></span>
              #{dataContext.getName()}"""

        ,
          id          : "entries_pool"
          name        : @t "entry.document.entry_many"
          field       : "entries_pool"
          resizable   : true
          sortable    : false
          minWidth    : 200
          formatter   : (row, cell, value, columnDef, dataContext) ->
            entries_pool = dataContext.get(columnDef.field)

            (_.map entries_pool.models, (entry) ->
              content = entry.get 'content'

              return content.DISPLAY_NAME if content
              App.t "protected.document.entry_deleted"
            ).join(', ')
        ,
          id          : "CREATE_DATE"
          name        : App.t 'global.create_date'
          field       : "CREATE_DATE"
          resizable   : true
          sortable    : true
          minWidth    : 100
          formatter   : (row, cell, value, columnDef, dataContext) ->
            moment.utc(dataContext.get(columnDef.field)).local().format('L LT')
        ,
          id          : "CHANGE_DATE"
          name        : App.t 'global.change_date'
          field       : "CHANGE_DATE"
          resizable   : true
          sortable    : true
          minWidth    : 100
          formatter   : (row, cell, value, columnDef, dataContext) ->
            moment.utc(dataContext.get(columnDef.field)).local().format('L LT')
        ,
          id          : "NOTE"
          name        : App.t 'protected.document.note'
          resizable   : true
          sortable    : true
          minWidth    : 200
          field       : "NOTE"
          editor      : Slick.BackboneEditors.Text
        ]

      expandGroup: (id, index) ->
        conditions = @tableData[index].get('conditions')

        for condition in conditions
          index = index + 1
          @tableData.splice index, 0, condition

          if not condition.collapsed
            index = index + 1

            @tableData.splice index, 0, condition.entries
            index += condition.entries.length - 1
