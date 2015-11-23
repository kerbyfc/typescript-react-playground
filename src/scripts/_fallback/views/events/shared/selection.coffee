  define [
    "app"
    "jquery"
    "lodash"
    "backbone"
    "marionette"

    "bootstrap"
    "views/controls/tree_view"
    "models/analysis/categories"
    "models/analysis/text_object"
    "models/policy/policy"

    "models/events/selections"

    "views/events/dialogs/select_categories"
    "views/shared/dialogs/select_elements"
    "views/events/dialogs/select_entities"

    "models/lists/fileformat"
    "models/lists/filetype"
    "models/lists/resourceGroups"

    "views/events/dialogs/select_entities"
  ], (WebGUI, $, Backbone, Marionette) ->
    "use strict"

    App.module "Events",
      startWithParent: true
      define: (Events, App, Backbone, Marionette, $) ->

        App.Views.Events ?= {}

        class App.Views.Events.Selection

          selectEntitiesDialog2: (category, element, e) ->
            e?.preventDefault()

            switch category
              when 'file_format'
                selected = _.map element.val().split(','), (item) -> item.split(':')[0]

                collectionFormatGroups = new App.Models.Files.FileFormatGroups
                collectionFormat = new App.Models.Files.FileFormats

                collectionFormatGroups.parse = (res) ->
                  _.each res.data, (model) ->
                    model.expand = false

                    model.format_id = model.format_type_id
                    model.children = collectionFormat.where({type_ref: model.format_type_id}).map (model) ->
                      model.set
                        title: model.get('name')
                        key: model.get 'format_id'
                        select: $.inArray(model.get('mime_type'), selected) isnt -1
                      model.toJSON()

                collectionFormat.fetch
                  silent: true
                  success: ->
                    App.modal2.show new App.Views.Events.SelectFileFormatDialog
                      title: App.t 'events.conditions.select_file_formats'
                      collection: collectionFormatGroups
                      formats_collection: collectionFormat
                      callback: (data) ->
                        data = _.filter data, (item) -> 'mime_type' of item.data

                        element.val(_.map data, (item) ->
                          "#{item.data.mime_type}:#{item.data.title}"
                        ).trigger('change')

              when 'perimeter_in', 'perimeter_out'
                if element.val() isnt ''
                  elements_ = _.map element.val().split(','), (item) -> item.split(':')[0]

                App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
                  title: App.t 'events.conditions.select_perimeters'
                  selected: elements_
                  collection: new App.Models.Lists.PerimetersPaginated(source: 'query')
                  table_config:
                    default:
                      sortCol: "DISPLAY_NAME"
                    columns: [
                      {
                        id      : "DISPLAY_NAME"
                        name    : App.t 'lists.tags.display_name_column'
                        field   : "DISPLAY_NAME"
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          App.Helpers.getPredefinedLocalizedValue dataContext.get(columnDef.field), 'lists.perimeters'
                      }
                      {
                        id      : "NOTE"
                        name    : App.t 'lists.tags.note_column'
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        field   : "NOTE"
                      }
                    ]
                  callback: (added, removed) ->
                    added = _.map added, (element) ->
                      "#{element.get('PERIMETER_ID')}:#{element.get('DISPLAY_NAME')}"
                    removed = _.map removed, (element) ->
                      "#{element.get('PERIMETER_ID')}:#{element.get('DISPLAY_NAME')}"

                    if element.val() isnt ''
                      initial = element.val().split(',')
                    else
                      initial = []

                    entities = _.union (_.difference initial, removed), added

                    element.val(entities.join(',')).trigger('change')

              when 'workstations'
                if element.val() isnt ''
                  elements_ = _.map element.val().split(','), (item) -> item.split(':')[1]

                App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
                  title: App.t 'events.conditions.select_workstations'
                  selected: elements_
                  collection: new App.Models.Policy.Workstations(source: 'query')
                  table_config:
                    default:
                      sortCol: "DISPLAYNAME"
                    columns: [
                      {
                        id      : "DISPLAYNAME"
                        name    : App.t 'lists.tags.display_name_column'
                        field   : "DISPLAYNAME"
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                      }
                      {
                        id      : "SERVER_NAME"
                        name    : App.t 'settings.ldap_settings.display_name'
                        resizable : true
                        sortable  : true
                        minWidth  : 100
                        cssClass  : "center"
                        field   : "SERVER_NAME"
                      }
                      {
                        id      : "SOURCE"
                        name    : App.t 'events.events.source'
                        resizable : true
                        sortable  : true
                        minWidth  : 80
                        cssClass  : "center"
                        field   : "SOURCE"
                        formatter     : (row, cell, value, columnDef, dataContext) ->
                          return dataContext.get(columnDef.field)?.toUpperCase()
                      }
                      {
                        id      : "NOTE"
                        name    : App.t 'lists.tags.note_column'
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        field   : "NOTE"
                      }
                    ]
                  callback: (added, removed) ->
                    added = _.map added, (element) ->
                      "workstation:#{element.get('WORKSTATION_ID')}:#{element.get('DISPLAYNAME')}"
                    removed = _.map removed, (element) ->
                      "workstation:#{element.get('WORKSTATION_ID')}:#{element.get('DISPLAYNAME')}"

                    if element.val() isnt ''
                      initial = element.val().split(',')
                    else
                      initial = []

                    entities = _.union (_.difference initial, removed), added

                    element.val(entities.join(',')).trigger('change')

              when 'tags'
                if element.val() isnt ''
                  elements_ = _.map element.val().split(','), (item) -> item.split(':')[0]

                App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
                  title: App.t 'events.conditions.tags_select'
                  selected: elements_
                  collection: new App.Models.Lists.Tags(source: 'query')
                  table_config:
                    default:
                      sortCol: "DISPLAY_NAME"
                    columns: [
                      {
                        id      : "COLOR"
                        name    : ""
                        field   : "COLOR"
                        width   : 40
                        resizable : false
                        sortable  : true
                        cssClass  : "center"
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          "<div style='height:16px;width:16px;background-color:#{dataContext.get('COLOR')}'></div>"
                      }
                      {
                        id      : "DISPLAY_NAME"
                        name    : App.t 'lists.tags.display_name_column'
                        field   : "DISPLAY_NAME"
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          App.Helpers.getPredefinedLocalizedValue dataContext.get(columnDef.field), "lists.tags"
                      }
                      {
                        id      : "NOTE"
                        name    : App.t 'lists.tags.note_column'
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        field   : "NOTE"
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          locale = App.t("lists.tags", { returnObjectTrees: true })

                          if dataContext.get(columnDef.field) and dataContext.get(columnDef.field).charAt(0) is '_' and
                             dataContext.get(columnDef.field).charAt(dataContext.get(columnDef.field).length - 1) is '_'
                            locale[dataContext.get(columnDef.field) + "note"]
                          else
                            dataContext.get(columnDef.field)
                      }
                    ]
                  callback: (added, removed) ->
                    added = _.map added, (element) ->
                      "#{element.get('TAG_ID')}:#{element.get('DISPLAY_NAME')}"
                    removed = _.map removed, (element) ->
                      "#{element.get('TAG_ID')}:#{element.get('DISPLAY_NAME')}"

                    if element.val() isnt ''
                      initial = element.val().split(',')
                    else
                      initial = []

                    entities = _.union (_.difference initial, removed), added

                    element.val(entities.join(',')).trigger('change')

              when 'policies'
                if element.val() isnt ''
                  elements_ = _.map element.val().split('||'), (item) -> item.split('::')[0]

                App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
                  title: App.t 'events.conditions.select_policy'
                  selected: elements_
                  collection: new App.Models.Policy.QueryList()
                  table_config:
                    default:
                      sortCol: "DISPLAY_NAME"
                    columns: [
                      {
                        id      : "STATUS"
                        name    : ""
                        field   : "STATUS"
                        width   : 40
                        resizable : false
                        sortable  : true
                        cssClass  : "center"
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          if parseInt(dataContext.get(columnDef.field), 10)
                            "<img src='/img/termin_active.png'>"
                          else
                            "<img src='/img/termin_inactive.png'>"
                      }
                      {
                        id      : "DISPLAY_NAME"
                        name    : App.t 'events.conditions.display_name_column'
                        field   : "DISPLAY_NAME"
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                      }
                      {
                        id      : "NOTE"
                        name    : App.t 'events.conditions.note_column'
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        field   : "NOTE"
                      }
                    ]
                  callback: (added_policies, removed_policies) ->
                    added_policies = _.map added_policies, (element) ->
                      "#{element.get('POLICY_ID')}::#{element.get('DISPLAY_NAME')}"
                    removed_policies = _.map removed_policies, (element) ->
                      "#{element.get('POLICY_ID')}::#{element.get('DISPLAY_NAME')}"

                    if element.val() isnt ''
                      initial = element.val().split('||')
                    else
                      initial = []

                    entities = _.union (_.difference initial, removed_policies), added_policies

                    element.val(entities.join('||')).trigger('change')

              when 'resources'
                if element.val() isnt ''
                  selected = _.map element.val().split(','), (item) -> item.split(':')[1]

                App.modal2.show new App.Views.Common.Dialogs.SelectElementsDialog
                  title: App.t 'lists.perimeters.select_resource_list'
                  selected: selected
                  collection: new App.Models.Lists.ResourceGroups(source: 'query')
                  table_config:
                    default:
                      sortCol: "DISPLAY_NAME"
                    columns: [
                      {
                        id      : "DISPLAY_NAME"
                        name    : App.t 'lists.tags.display_name_column'
                        field   : "DISPLAY_NAME"
                        resizable : true
                        sortable  : true
                        minWidth  : 150
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          locale = App.t("lists.resources", { returnObjectTrees: true })

                          if dataContext.get(columnDef.field)?.charAt(0) is '_' and
                             dataContext.get(columnDef.field)?.charAt(dataContext.get(columnDef.field).length - 1) is '_'
                            locale[dataContext.get(columnDef.field)]
                          else
                            dataContext.get(columnDef.field)
                      }
                      {
                        id      : "CREATE_DATE"
                        name    : App.t 'events.conditions.create_date_column'
                        field   : "CREATE_DATE"
                        resizable : true
                        sortable  : true
                        minWidth  : 100
                        formatter : (row, cell, value, columnDef, dataContext) ->
                          if dataContext.get(columnDef.field)
                            App.Helpers.show_datetime(dataContext.get(columnDef.field))
                      }
                    ]
                  callback: (added, removed) ->
                    if element.val() isnt ''
                      entities = element.val().split(',')
                    else
                      entities = []

                    entities = _.union entities, _.map added, (resource) ->
                      "list:#{resource.get('LIST_ID')}:#{resource.get('DISPLAY_NAME')}"

                    entities = _.difference entities, _.map removed, (resource) ->
                      "list:#{resource.get('LIST_ID')}:#{resource.get('DISPLAY_NAME')}"

                    element.val(entities).trigger('change')

              when 'senders', 'recipients'
                if element.val() isnt ''
                  entities_ = _.map element.val().split(',')

                App.modal2.show new App.Views.Events.SelectEntitiesDialog
                  title: App.t 'events.conditions.select_parcipants'
                  selected: entities_
                  callback: (entities) ->
                    element.val(entities).trigger('change')

          format_simple_id: (options, data) ->
            return data[options.id_key] + options.delimeter + data[options.display_key]

          simple_elemet_init: (options, element, callback) ->
            data = []

            $(element.val().split(options.separator)).each (i) ->
              item = @split(options.delimeter)

              o = {}
              o['id'] = @
              o[options.id_key] = item[0]
              o[options.display_key] = item[1]

              data.push o

            element.val('')

            callback(data)

          format_simple_entity_display_value: (category, data) ->
            switch category
              when 'tags'
                return '<div>' + App.Helpers.getPredefinedLocalizedValue(data.DISPLAY_NAME, 'lists.tags') + '</div>'
              when 'perimeter_in', 'perimeter_out'
                return '<div>' + App.Helpers.getPredefinedLocalizedValue(data.DISPLAY_NAME, 'lists.perimeters') + '</div>'
              when 'policies'
                return '<div>' + data.DISPLAY_NAME + '</div>'
              when 'file_format'
                return '<div>' + data.name + '</div>'

          format_simple_search_value: (category, data) ->
            switch category
              when 'tags'
                displan_name = App.Helpers.getPredefinedLocalizedValue(data.DISPLAY_NAME, 'lists.tags')
                dom_element = $("<span>#{displan_name} (#{App.Helpers.show_datetime data.CREATE_DATE})</span>")
              when 'perimeter_in', 'perimeter_out'
                displan_name = App.Helpers.getPredefinedLocalizedValue(data.DISPLAY_NAME, 'lists.perimeters')
                dom_element = $("<span>#{displan_name} (#{App.Helpers.show_datetime data.CREATE_DATE})</span>")
              when 'policies'
                dom_element = $("<span>#{data.DISPLAY_NAME} (#{App.Helpers.show_datetime data.CREATE_DATE})</span>")
              when 'file_format'
                dom_element = $("<div>#{data.name}</div>")

            if parseInt(data.IS_DELETED, 10) is 1
              dom_element.addClass('element-deleted')

            return ($('<div/>').append(dom_element)).prop('outerHTML')

          parse_search_results: (category, data, page, query) ->
            result = []

            if data.data.person
              result = _.union result, data.data.person

            if data.data.group
              result = _.union result, data.data.group

            if data.data.status
              result = _.union result, data.data.status

            if data.data.workstation
              result = _.union result, data.data.workstation

            if data.data.tag
              result = _.union result, data.data.tag

            if data.data.perimeter
              result = _.union result, data.data.perimeter

            if data.data.policy
              result = _.union result, data.data.policy

            if data.data.fingerprint
              result = _.union result, data.data.fingerprint

            if data.data.category
              result = _.union result, data.data.category

            if data.data.etForm
              result = _.union result, data.data.etForm

            if data.data.etStamp
              result = _.union result, data.data.etStamp

            if data.data.textObject
              result = _.union result, data.data.textObject

            if data.data.etTable
              result = _.union result, data.data.etTable

            if @element_options[category]?.create_choise
              result = _.union result, @element_options[category]?.create_choise(query.term)

            return {
              results: result
            }

          # =============================================
          # Resources
          # =============================================
          format_resource_search_value: (data) ->
            resource_locale = App.t('lists.resources', { returnObjectTrees: true })

            switch data.TYPE
              when 'destination_host'
                return '<div><i class="fontello-icon-globe-1"></i>' + data.DISPLAY_NAME + '</div>'
              when 'list'
                name = data.DISPLAY_NAME
                if name.charAt(0) is '_' and name.charAt(name.length - 1) is '_'
                  name = resource_locale[name]

                if data.CREATE_DATE
                  dom_element = $("<span>#{name} (#{App.Helpers.show_datetime data.CREATE_DATE})</span>")
                else
                  dom_element = $("<span>#{name}</span>")

                dom_element.addClass('fontello-icon-tag-empty')

                if parseInt(data.IS_DELETED, 10) is 1
                  dom_element.addClass('element-deleted')

                return ($('<div/>').append(dom_element)).prop('outerHTML')

          format_resource_display_value: (data) ->
            resource_locale = App.t('lists.resources', { returnObjectTrees: true })

            switch data.TYPE
              when 'destination_host'
                return '<div><i class="fontello-icon-globe-1"></i>' + data.DISPLAY_NAME + '</div>'
              when 'list'
                name = data.DISPLAY_NAME
                if name.charAt(0) is '_' and name.charAt(name.length - 1) is '_'
                  name = resource_locale[name]

                return '<div><i class="fontello-icon-tag-empty"></i>' + name + '</div>'

          format_resource_id: (data) ->
            return data.TYPE + ":" + data.LIST_ID + ":" + data.DISPLAY_NAME

          format_resource_init: (element, callback) ->
            data = []

            $(element.val().split(",")).each (i) ->
              item = @split(':')
              data.push {
                id: @
                TYPE: item[0]
                LIST_ID: item[1]
                DISPLAY_NAME: item[2]
              }

            element.val('')

            callback(data)

          # =============================================
          # Analysis shared helpers
          # =============================================
          analysis_init: (options, element, callback) ->
            data = []

            $(element.val().split(options.separator)).each (i) ->
              item = @split(options.delimeter)

              switch item[0]
                when 'etalon_forms'
                  data.push {
                    id: @
                    FINGERPRINT_ID: item[1]
                    TYPE: 'form'
                    DISPLAY_NAME: item[2]
                  }
                when 'etalon_database'
                  data.push {
                    id: @
                    FINGERPRINT_ID: item[1]
                    TYPE: 'table'
                    DISPLAY_NAME: item[2]
                  }
                when 'etalon_stamps'
                  data.push {
                    id: @
                    FINGERPRINT_ID: item[1]
                    TYPE: 'stamp'
                    DISPLAY_NAME: item[2]
                  }
                when 'fingerprints'
                  data.push {
                    id: @
                    FINGERPRINT_ID: item[1]
                    TYPE: 'fingerprint'
                    DISPLAY_NAME: item[2]
                  }
                when 'text_objects'
                  data.push {
                    id: @
                    TEXT_OBJECT_ID: item[1]
                    DISPLAY_NAME: item[2]
                  }
                when 'categories'
                  data.push {
                    id: @
                    CATEGORY_ID: item[1]
                    DISPLAY_NAME: item[2]
                  }

            element.val('')

            callback(data)

          format_analysis_search_value: (category, data) ->
            dom_element = $("<span>#{data.DISPLAY_NAME} (#{App.Helpers.show_datetime data.CREATE_DATE})</span>")

            if data.FINGERPRINT_ID
              switch data.TYPE
                when 'form'
                  dom_element.addClass('fontello-icon-vcard')

                when 'table'
                  dom_element.addClass('fontello-icon-list-alt')

                when 'stamp'
                  dom_element.addClass('fontello-icon-certificate')

                when 'fingerprint'
                  dom_element.addClass('fontello-icon-doc-text')

            if data.TEXT_OBJECT_ID
              dom_element.addClass('fontello-icon-credit-card')

            if data.CATEGORY_ID
              dom_element.addClass('fontello-icon-folder')

            if parseInt(data.IS_DELETED, 10) is 1
              dom_element.addClass('element-deleted')

            return ($('<div/>').append(dom_element)).prop('outerHTML')

          format_analysis_display_value: (category, data) ->
            if data.FINGERPRINT_ID
              switch data.TYPE
                when 'form'
                  return '<div><span class="fontello-icon-vcard"></span>' + data.DISPLAY_NAME + '</div>'
                when 'table'
                  return '<div><span class="fontello-icon-list-alt"></span>' + data.DISPLAY_NAME + '</div>'
                when 'stamp'
                  return '<div><span class="fontello-icon-certificate"></span>' + data.DISPLAY_NAME + '</div>'
                when 'fingerprint'
                  return '<div><span class="fontello-icon-doc-text"></span>' + data.DISPLAY_NAME + '</div>'

            if data.TEXT_OBJECT_ID
              return '<div><span class="fontello-icon-credit-card"></span>' + data.DISPLAY_NAME + '</div>'
            if data.CATEGORY_ID
              return '<div><span class="fontello-icon-folder"></span>' + data.DISPLAY_NAME + '</div>'

          format_analysis_id: (options, data) ->
            if data.FINGERPRINT_ID
              switch data.TYPE
                when 'form'
                  return 'etalon_forms' + ':' + data.FINGERPRINT_ID + ":" + data.DISPLAY_NAME
                when 'table'
                  return 'etalon_database' + ':' + data.FINGERPRINT_ID + ":" + data.DISPLAY_NAME
                when 'stamp'
                  return 'etalon_stamps' + ':' + data.FINGERPRINT_ID + ":" + data.DISPLAY_NAME
                when 'fingerprint'
                  return 'fingerprints' + ':' + data.FINGERPRINT_ID + ":" + data.DISPLAY_NAME

            if data.TEXT_OBJECT_ID then   return 'text_objects' + ':' + data.TEXT_OBJECT_ID + ":" + data.DISPLAY_NAME
            if data.CATEGORY_ID then    return 'categories' + ':' + data.CATEGORY_ID + ":" + data.DISPLAY_NAME

          # =============================================
          # Senders/recipients helpers
          # =============================================
          senders_recipients_init: (element, callback) ->
            data = []

            $(element.val().split(",")).each (i) ->
              item = @split(':')

              switch item[0]
                when 'person'
                  data.push {
                    id: @
                    PERSON_ID: item[1]
                    DISPLAYNAME: item[2]
                    SOURCE: item[3]
                    SERVER_NAME: item[4]
                  }
                when 'phone'
                  data.push {
                    id: @
                    PHONE: true
                    DISPLAYNAME: item[2]
                  }
                when 'skype'
                  data.push {
                    id: @
                    SKYPE: true
                    DISPLAYNAME: item[2]
                  }
                when 'icq'
                  data.push {
                    id: @
                    ICQ: true
                    DISPLAYNAME: item[2]
                  }
                when 'email'
                  data.push {
                    id: @
                    EMAIL: true
                    DISPLAYNAME: item[2]
                  }
                when 'lotus'
                  data.push {
                    id: @
                    LOTUS: true
                    DISPLAYNAME: item[2]
                  }
                when 'group'
                  data.push {
                    id: @
                    GROUP_ID: item[1]
                    DISPLAYNAME: item[2]
                    SOURCE: item[3]
                    SERVER_NAME: item[4]
                  }

                when 'status'
                  data.push {
                    id: @
                    IDENTITY_STATUS_ID: item[1]
                    DISPLAY_NAME: item[2]
                  }

            element.val('')

            callback(data)

          senders_recipients_create_choise: (term) ->
            return [
              {
                PHONE: term
                DISPLAYNAME: term
              }
              {
                EMAIL: term,
                DISPLAYNAME: term
              }
              {
                LOTUS: term,
                DISPLAYNAME: term
              }
              {
                ICQ: term,
                DISPLAYNAME: term
              }
              {
                SKYPE: term,
                DISPLAYNAME: term
              }
            ]

          format_sender_recipients_search_value: (data) ->
            locale = App.t("lists.statuses", { returnObjectTrees: true })
            server_lbl = App.t 'events.conditions.server'

            if data.PERSON_ID
              return """
                <div style="margin-bottom: .3em;">
                  <div>
                    <span class="fontello-icon-user"></span>
                    #{if data.SOURCE then data.SOURCE?.toUpperCase() + ':'}
                    #{data.DISPLAYNAME}
                  <div>
                  #{if data.SERVER_NAME then "<div style='font-size: 12px;'>#{server_lbl}: #{data.SERVER_NAME}</div>"}
                </div>
              """

            if data.GROUP_ID
              return """
                <div style="margin-bottom: .3em;">
                  <div>
                    <span class="fontello-icon-users-1"></span>
                    #{ if data.SOURCE then data.SOURCE?.toUpperCase() + ':'}
                    #{data.DISPLAYNAME}
                  <div>
                  #{if data.SERVER_NAME then "<div style='font-size: 12px;'>#{server_lbl}: #{data.SERVER_NAME}</div>"}
                </div>
              """

            if data.EMAIL then        return '<div><i class="i-unit-contact__mail"></i>' + data.DISPLAYNAME + '</div>'
            if data.LOTUS then        return '<div><i class="i-unit-contact__lotus"></i>' + data.DISPLAYNAME + '</div>'
            if data.PHONE then        return '<div><i class="i-unit-contact__mobile"></i>' + data.DISPLAYNAME + '</div>'
            if data.ICQ then        return '<div><i class="i-unit-contact__icq"></i>' + data.DISPLAYNAME + '</div>'
            if data.SKYPE then        return '<div><i class="i-unit-contact__skype"></i>' + data.DISPLAYNAME + '</div>'
            if data.IDENTITY_STATUS_ID
              if data.DISPLAY_NAME.charAt(0) is '_' and
                 data.DISPLAY_NAME.charAt(data.DISPLAY_NAME.length - 1) is '_'
                return '<div><i class="[ icon _status ]"></i>' + locale[data.DISPLAY_NAME] + '</div>'
              else
                return '<div><i class="[ icon _status ]"></i>' + data.DISPLAY_NAME + '</div>'

          format_sender_recipients_display_value: (data) ->
            locale = App.t("lists.statuses", { returnObjectTrees: true })

            if data.PERSON_ID
              return  """<div>
                <span class='fontello-icon-user'></span>
                #{data.DISPLAYNAME}
                <i class="fontello-icon-info-circle-1 entity_info" data-type='person' data-id='#{data.PERSON_ID}'></i>
                </div>
              """

            if data.GROUP_ID
              return  """<div>
                <span class='fontello-icon-users-1'></span>
                #{data.DISPLAYNAME}
                <i class="fontello-icon-info-circle-1 entity_info" data-type='group' data-id='#{data.GROUP_ID}'></i>
                </div>
              """

            if data.EMAIL then        return '<div><i class="i-unit-contact__mail"></i>' + data.DISPLAYNAME + '</div>'
            if data.LOTUS then        return '<div><i class="i-unit-contact__lotus"></i>' + data.DISPLAYNAME + '</div>'
            if data.PHONE then        return '<div><i class="i-unit-contact__mobile"></i>' + data.DISPLAYNAME + '</div>'
            if data.ICQ then        return '<div><i class="i-unit-contact__icq"></i>' + data.DISPLAYNAME + '</div>'
            if data.SKYPE then        return '<div><i class="i-unit-contact__skype"></i>' + data.DISPLAYNAME + '</div>'
            if data.IDENTITY_STATUS_ID
              if data.DISPLAY_NAME.charAt(0) is '_' and
                 data.DISPLAY_NAME.charAt(data.DISPLAY_NAME.length - 1) is '_'
                return '<div><i class="[ icon _status ]"></i>' + locale[data.DISPLAY_NAME] + '</div>'
              else
                return '<div><i class="[ icon _status ]"></i>' + data.DISPLAY_NAME + '</div>'

          format_senders_recipients_id: (data) ->
            if data.PERSON_ID then        return "person:#{data.PERSON_ID}:#{data.DISPLAYNAME}"
            if data.GROUP_ID then       return "group:#{data.GROUP_ID}:#{data.DISPLAYNAME}"
            if data.EMAIL then          return "email" + ':' + ":" + data.DISPLAYNAME
            if data.LOTUS then          return "lotus" + ':' + ":" + data.DISPLAYNAME
            if data.PHONE then          return "phone" + ':' + ':' + data.DISPLAYNAME
            if data.ICQ then          return "icq" + ":" + ':' + data.DISPLAYNAME
            if data.SKYPE then          return 'skype' + ":" + ':' + data.DISPLAYNAME
            if data.IDENTITY_STATUS_ID then   return 'status:' + data.IDENTITY_STATUS_ID + ":" + data.DISPLAY_NAME

          # =============================================
          # Workstation shared helpers
          # =============================================
          workstations_init: (element, callback) ->
            data = []

            $(element.val().split(",")).each (i) ->
              item = @split(':')

              switch item[0]
                when 'workstation'
                  data.push {
                    id: @
                    WORKSTATION_ID: item[1]
                    DISPLAYNAME: item[2]
                    SOURCE: item[3]
                    SERVER_NAME: item[4]
                  }
                when 'ip'
                  data.push {
                    id: @
                    IP: item[1]
                    DISPLAYNAME: item[2]
                  }
                when 'dnshostname'
                  data.push {
                    id: @
                    DNS: item[1]
                    DISPLAYNAME: item[2]
                  }

            element.val('')

            callback(data)

          format_workstations_search_value: (data) ->
            server_lbl = App.t 'events.conditions.server'
            server_name = data.SERVER_NAME

            if data.WORKSTATION_ID
              return """
                <div style="margin-bottom: .3em;">
                <div>
                  <span class="[ icon _sizeSmall _computer ]"></span>
                  #{if data.SOURCE then data.SOURCE?.toUpperCase() + ':'} #{data.DISPLAYNAME}
                <div>
                #{if data.SERVER_NAME then "<div style='font-size:12px;'>#{server_lbl}: #{server_name}</div>"}
                </div>
              """

            if data.IP
              return '<div>IP:' + data.DISPLAYNAME + '</div>'

            if data.DNS
              return '<div>DNS: ' + data.DISPLAYNAME + '</div>'

          format_workstations_display_value: (data) ->
            if data.WORKSTATION_ID
              return  """<div>
                <span class='[ icon _sizeSmall _computer ]'></span>
                #{data.DISPLAYNAME}
                <i class="fontello-icon-info-circle-1 entity_info" data-type='workstation' data-id='#{data.WORKSTATION_ID}'></i>
                </div>
              """
            if data.IP then         return '<div>IP: ' + data.DISPLAYNAME + '</div>'
            if data.DNS then        return '<div>DNS: ' + data.DISPLAYNAME + '</div>'

          format_workstations_id: (data) ->
            if data.WORKSTATION_ID then   return "workstation:#{data.WORKSTATION_ID}:#{data.DISPLAYNAME}"
            if data.IP then         return 'ip:' + data.IP + ":" + data.DISPLAYNAME
            if data.DNS then        return "dnshostname:" + data.DNS + ":" + data.DISPLAYNAME

          workstations_create_choise: (term, data) ->
            result = []

            if App.Helpers.patterns.ip.test term
              result.push {
                IP: term
                DISPLAYNAME: term
              }
            else
              result.push {
                DNS: term
                DISPLAYNAME: term
              }

            return result

          showEntityInfo: ->
            @$el.find('.entity_info').popover('destroy')
            @$el.find('.entity_info').popover
              html: true
              placement: 'bottom'
              trigger: 'click'
              content: ->
                type = $(@).data('type')
                id = $(@).data('id')

                switch type
                  when 'group'
                    model = new App.Models.Organization.Group({GROUP_ID: id})
                    model.set('identity_keys', $(@).data('keys')?.split('||'))
                    view = new App.Views.Organization.Person
                      template: 'events/dialogs/group_query_info.ect.html'
                      className: "popover_unit"
                      tagName: "div"
                      model: model

                    # Душим события
                    # ToDo: некрасиво как-то.
                    view.events.mousedown = null
                    view.events.mouseenter = null

                    model.fetch
                      success: (model, response, options) -> view.render()

                  when 'person'
                    model = new App.Models.Organization.Person({PERSON_ID: id})
                    model.set('identity_keys', $(@).data('keys')?.split('||'))
                    view = new App.Views.Organization.Person
                      template: 'events/dialogs/person_query_info.ect.html'
                      className: "popover_unit"
                      tagName: "div"
                      model: model

                    # Душим события
                    # ToDo: некрасиво как-то.
                    view.events.mousedown = null
                    view.events.mouseenter = null

                    model.fetch
                      success: (model, response, options) -> view.render()

                  when 'workstation'
                    model = new App.Models.Organization.Workstation({WORKSTATION_ID: id})
                    model.set('identity_key', $(@).data('key'))
                    view = new App.Views.Organization.Workstation
                      template: 'events/dialogs/workstation_query_info.ect.html'
                      className: "popover_unit"
                      tagName: "div"
                      model: model

                    # Душим события
                    # ToDo: некрасиво как-то.
                    view.events.mousedown = null
                    view.events.mouseenter = null

                    model.fetch
                      success: (model, response, options) -> view.render()

                return view.$el
              container: 'form'

            .click (e) ->
              e.preventDefault()
              e.stopPropagation()

              $('.entity_info').each ->
                if not $(@).is(e.target) and $(@).has(e.target).length is 0 and $('.popover').has(e.target).length is 0
                  $(@).popover('hide')

          constructor: ->
            @element_options =
              senders:
                url           : "#{App.Config.server}/api/search?scopes=person,group,status&limit=-1&with="
                minimumInputLength    : 3
                separator       : ","
                init          : @senders_recipients_init
                format_id       : @format_senders_recipients_id
                format_search     : @format_sender_recipients_search_value
                format_display_value  : @format_sender_recipients_display_value
                create_choise     : @senders_recipients_create_choise
              recipients:
                url           : "#{App.Config.server}/api/search?scopes=person,group,status&limit=-1&with="
                minimumInputLength    : 3
                separator       : ","
                init          : @senders_recipients_init
                format_id       : @format_senders_recipients_id
                format_search     : @format_sender_recipients_search_value
                format_display_value  : @format_sender_recipients_display_value
                create_choise     : @senders_recipients_create_choise
              workstations:
                url           : "#{App.Config.server}/api/search?scopes=workstation"
                minimumInputLength    : 3
                separator       : ","
                init          : @workstations_init
                format_id       : @format_workstations_id
                format_search     : @format_workstations_search_value
                format_display_value  : @format_workstations_display_value
                create_choise     : @workstations_create_choise
              policies:
                display_key       : 'DISPLAY_NAME'
                id_key          : 'POLICY_ID'
                url           : "#{App.Config.server}/api/search?type=query&scopes=policy"
                minimumInputLength    : 3
                separator       : "||"
                delimeter       : "::"
                init          : @simple_elemet_init
                format_id       : @format_simple_id
                format_display_value  : @format_simple_entity_display_value
                format_search     : @format_simple_search_value
              tags:
                display_key       : 'DISPLAY_NAME'
                id_key          : 'TAG_ID'
                url           : "#{App.Config.server}/api/search?type=query&scopes=tag"
                minimumInputLength    : 1
                separator       : ","
                delimeter       : ":"
                init          : @simple_elemet_init
                format_id       : @format_simple_id
                format_display_value  : @format_simple_entity_display_value
                format_search     : @format_simple_search_value
              perimeter_in:
                display_key       : 'DISPLAY_NAME'
                id_key          : 'PERIMETER_ID'
                url           : "#{App.Config.server}/api/search?type=query&scopes=perimeter"
                separator       : ","
                delimeter       : ":"
                minimumInputLength    : 1
                init          : @simple_elemet_init
                format_id       : @format_simple_id
                format_display_value  : @format_simple_entity_display_value
                format_search     : @format_simple_search_value
              perimeter_out:
                display_key       : 'DISPLAY_NAME'
                id_key          : 'PERIMETER_ID'
                separator       : ","
                delimeter       : ":"
                url           : "#{App.Config.server}/api/search?type=query&scopes=perimeter"
                minimumInputLength    : 1
                init          : @simple_elemet_init
                format_id       : @format_simple_id
                format_display_value  : @format_simple_entity_display_value
                format_search     : @format_simple_search_value
              analysis:
                separator       : ","
                delimeter       : ":"
                minimumInputLength    : 1
                url           : "#{App.Config.server}/api/search?scopes=fingerprint,category,\
                               etForm,etStamp,textObject,etTable&type=query"
                init          : @analysis_init
                format_id       : @format_analysis_id
                format_display_value  : @format_analysis_display_value
                format_search     : @format_analysis_search_value
              resources:
                separator       : ","
                delimeter       : ":"
              file_format:
                display_key       : 'name'
                id_key          : 'mime_type'
                minimumInputLength    : 3
                separator       : ","
                delimeter       : ":"
                format_id       : @format_simple_id
                init          : @simple_elemet_init
                format_display_value  : @format_simple_entity_display_value
                format_search     : @format_simple_search_value
