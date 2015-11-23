"use strict"

require "common/backbone-tree.coffee"

App.module "Analysis",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Analysis ?= {}

    validation =
      DISPLAY_NAME: [
        required : true
      ,
        rangeLength : [1, 256]
      ]

    class App.Models.Analysis.GroupItem extends App.Common.ModelTree

      idAttribute: "CATEGORY_ID"

      parentIdAttribute: "PARENT_CATEGORY_ID"

      type: 'group'

      urlRoot: "#{App.Config.server}/api/category"

      islock: (o) ->
        o = action: o if _.isString o

        o.type = @entryType
        super o

      defaults: ->
        defaults =
          TYPE    : @entryType
          ENABLED : 1

        _.extend defaults, @_config

        selected = @collection.getSelectedModels?()
        return defaults if not selected or not selected.length

        _.each _.keys(defaults), (key) -> defaults[key] = selected[0].get key
        _.extend defaults, PARENT_CATEGORY_ID: selected[0].id

      validation: validation

    class App.Models.Analysis.GroupTermItem extends App.Models.Analysis.GroupItem

      countAttribute: 'TERM_COUNT'

      morphology: [
        "ukr"
        "tur"
        "srp"
        "spa"
        "rus"
        "ron"
        "pol"
        "lav"
        "ita"
        "fra"
        "eng"
        "deu"
        "bel"
        "aze"
        "ara"
      ]

      type: 'category'

      entryType: 'term'

      isCanContainsOnlyFolders: false

      _config:
        TERM_WEIGHT         : 5
        TERM_CASE_SENSITIVE : 0
        TERM_MORPHOLOGY     : 1
        TERM_LANGUAGE       : 'rus'

      validation: _.extend validation,
        TERM_WEIGHT:
          range : [1, 10]
          msg   : 'analysis.category.category_term_weight_validation_error'

      relation: ->
        TERM_CASE_SENSITIVE: (value) ->
          return unless value
          field : 'TERM_MORPHOLOGY'
          value : 0

        TERM_MORPHOLOGY: (value) ->
          return unless value
          field : 'TERM_CASE_SENSITIVE'
          value : 0

        TERM_LANGUAGE: (value) =>
          _data = field: 'TERM_MORPHOLOGY'
          isMophology = value in @morphology
          _data.disabled = if isMophology then false else true
          _data.hide = if isMophology then false else true
          if @isNew()
            _data.value = if isMophology then 1 else 0
          _data

    class App.Models.Analysis.GroupTextObjectItem extends App.Models.Analysis.GroupItem

      countAttribute: 'TO_COUNT'

      entryType: 'text_object'

      type: 'group_text_object'

    class App.Models.Analysis.GroupFingerprintItem extends App.Models.Analysis.GroupItem

      countAttribute: 'FINGERPRINT_COUNT'

      entryType: 'fingerprint'

      type: 'group_fingerprint'

      _config:
        FP_TEXT_VALUE_THRESHOLD : 10
        FP_BIN_VALUE_THRESHOLD  : 10

    class App.Models.Analysis.GroupFormItem extends App.Models.Analysis.GroupItem

      countAttribute: 'ET_FORM_COUNT'

      entryType: 'form'

      type: 'group_form'

    class App.Models.Analysis.GroupStampItem extends App.Models.Analysis.GroupItem

      countAttribute: 'STAMP_COUNT'

      entryType: 'stamp'

      type: 'group_stamp'

    class App.Models.Analysis.GroupTableItem extends App.Models.Analysis.GroupItem

      countAttribute: 'ET_TABLE_COUNT'

      entryType: 'table'

      type: 'group_table'


    class App.Models.Analysis.Group extends App.Common.CollectionTree

      acceptTypes: '.cfb'

      model: App.Models.Analysis.GroupItem

      buttons: [ "create", "edit", "delete", "import", "export" ]

      islock: (data) ->
        data = action: data if _.isString data

        if data.action and ( data.action is 'export' or data.action is 'import' )
          data =
            module : 'analysis'
            action : 'export'
        else
          data.type = @entryType

        super data

      toolbar: ->
        create: (selected) ->
          return false unless selected.length
          return false if selected[0].isRoot()
          if selected[0].id is '1ABECC84F2360B94E0533D003C0A80AE00000000' and @entryType is 'table'
            return true

          return true if selected[0].entryType is 'term' and selected[0].count()
          parent = selected[0].getParentModel()

          node = @getNodeByKey selected[0].id
          return [
            2
            selected[0].t 'level',
              max   : 7
              context : 'error'
          ] if node and node.getLevel() > 6

          false

        edit: (selected) ->
          return true if selected.length isnt 1
          parent = selected[0].getParentModel()
          return true if selected[0].isRoot()
          false

        delete: (selected) ->
          return true if selected.length isnt 1

          if node = @getNodeByKey(selected[0].id)
            pdChild = []
            isChild = node.visit (node) ->
              if node.data.protected_documents.length
                pdChild.push
                  name : node.data.DISPLAY_NAME
                  protected_documents : _.pluck(node.data.protected_documents, 'DISPLAY_NAME')
              true

            if pdChild.length
              title = Marionette.Renderer.render "controls/popover/pd_child_error",
                name     : selected[0].getName()
                type     : selected[0].type
                document : pdChild

              return [2, title]

          pd = selected[0].get 'protected_documents'
          if pd.length
            title = Marionette.Renderer.render "controls/popover/pd_error",
              name     : selected[0].getName()
              type     : selected[0].type
              document : _.pluck(pd, 'DISPLAY_NAME')

            return [2, title]

          parent = selected[0].getParentModel()
          return true if selected[0].isRoot()
          if selected[0].id is '1ABECC84F2360B94E0533D003C0A80AE00000000' and @entryType is 'table'
            return true

          false

    class App.Models.Analysis.GroupTerm extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupTermItem

      buttons: [ "create", "edit", "delete", "import", "export" ]

    class App.Models.Analysis.GroupTextObject extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupTextObjectItem

    class App.Models.Analysis.GroupFingerprint extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupFingerprintItem

    class App.Models.Analysis.GroupForm extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupFormItem

    class App.Models.Analysis.GroupStamp extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupStampItem

    class App.Models.Analysis.GroupTable extends App.Models.Analysis.Group

      model: App.Models.Analysis.GroupTableItem
