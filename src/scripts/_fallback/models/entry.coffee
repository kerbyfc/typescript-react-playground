"use strict"

require "backbone.paginator"

helpers = require "common/helpers.coffee"

Dashboards = require "models/dashboards/dashboards.coffee"
Events = require "models/events/events.coffee"
Selection = require "models/events/selections.coffee"

require "models/settings/audit_events/audit_events.coffee"
Licenses = require "models/settings/licenses.coffee"
Scopes = require "models/settings/scope.coffee"
Roles = require "models/settings/role.coffee"
LdapServers = require "models/settings/adconfig.coffee"
SystemCheck = require "models/settings/system_check.coffee"

require "models/protected/document.coffee"
require "models/protected/catalog.coffee"
Fileformat = require "models/lists/fileformat.coffee"
Filetype = require "models/lists/filetype.coffee"
require "models/analysis/category.coffee"
require "models/analysis/form.coffee"
require "models/analysis/stamp.coffee"
require "models/analysis/table.coffee"
require "models/analysis/fingerprint.coffee"
require "models/analysis/graphic.coffee"
require "models/analysis/term.coffee"
require "models/analysis/text_object.coffee"
require "models/analysis/text_object_pattern.coffee"
require "models/organization/groups.coffee"

class Backbone.LocalModel extends App.Common.ValidationModel

  idAttribute: "id"

  nameAttribute: "NAME"

  local: true

  validation:
    NAME : [
      required: true
      msg: App.t "form.error.required",
        postProcess: 'sprintf'
        sprintf: [
          App.t "select_dialog.contact"
        ]
    ,
      fn: (value, attr, model) ->
        App.t "form.error.error_#{model.TYPE}" unless App.Helpers.isValid model.TYPE, value
    ]

  t: (key, options = {}) ->
    if options.context is 'type'
      return @t "select_dialog.#{key}"
    super

  sync: (type, model, options) ->
    options.success
      id   : model.id
      NAME : model.id
      ID   : model.id

  islock: -> false

App.Models.Entry ?= {}

class App.Models.Entry.DnsItem extends Backbone.LocalModel
class App.Models.Entry.IpItem extends Backbone.LocalModel
class App.Models.Entry.UrlItem extends Backbone.LocalModel


class App.Models.Entry.AuditEventItem extends App.Models.AuditEvents.Model
  urlRoot: "#{App.Config.server}/api/auditLog"
class App.Models.Entry.AuditEvent extends App.Models.AuditEvents.Collection

class App.Models.Entry.ScopeItem extends Scopes.Model
class App.Models.Entry.Scope extends Scopes.Collection

class App.Models.Entry.LicenseItem extends Licenses.Model
class App.Models.Entry.License extends Licenses.Collection

class App.Models.Entry.LdapItem extends LdapServers.Model
class App.Models.Entry.Ldap extends LdapServers.Collection

class App.Models.Entry.RoleItem extends Roles.Model
class App.Models.Entry.Role extends Roles.Collection

class App.Models.Entry.HealthcheckItem extends Backbone.Model
  # уточнить id
  idAttribute: "rows"

  urlRoot: "#{App.Config.server}/api/systemCheck"
class App.Models.Entry.Healthcheck extends SystemCheck.Collection


class App.Models.Entry.DashboardItem extends Dashboards.Model
class App.Models.Entry.Dashboard extends Dashboards.Collection

class App.Models.Entry.EventItem extends Events.Model
class App.Models.Entry.Event extends Events.Collection

class App.Models.Entry.SelectionItem extends Selection.model
class App.Models.Entry.Selection extends Selection.collection

class App.Models.Entry.CategoryItem extends Backbone.Model

  idAttribute: 'CATEGORY_ID'

  urlRoot: "#{App.Config.server}/api/category"

  islock: (o) ->
    o.type = o.type.replace "group_", ""
    o.type = 'term' if o.type is 'category'
    super

class App.Models.Entry.GroupTermItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.GroupTextObjectItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.GroupFingerprintItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.GroupFormItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.GroupStampItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.GroupTableItem extends App.Models.Entry.CategoryItem
class App.Models.Entry.Category extends App.Models.Analysis.GroupTerm
class App.Models.Entry.GroupTextObject extends App.Models.Analysis.GroupTextObject
class App.Models.Entry.GroupFingerprint extends App.Models.Analysis.GroupFingerprint
class App.Models.Entry.GroupForm extends App.Models.Analysis.GroupForm
class App.Models.Entry.GroupStamp extends App.Models.Analysis.GroupStamp
class App.Models.Entry.GroupTable extends App.Models.Analysis.GroupTable

class App.Models.Entry.CatalogItem extends Backbone.Model
  idAttribute: "CATALOG_ID"

  urlRoot: "#{App.Config.server}/api/protectedCatalog"

  islock: ->
    helpers.islock { module: 'protected', action: 'show' }

class App.Models.Entry.Catalog extends App.Models.Protected.Catalog

class App.Models.Entry.DocumentItem extends App.Models.Protected.DocumentItem

  islock: ->
    helpers.islock { module: 'protected', action: 'show' }

class App.Models.Entry.Document extends App.Models.Protected.Document

class App.Models.Entry.GroupItem extends App.Common.ModelTree

  idAttribute: 'GROUP_ID'

  parentIdAttribute: 'PARENT_GROUP_ID'

  urlRoot: "#{App.Config.server}/api/ldapGroup"

class App.Models.Entry.Group extends App.Common.CollectionTree

  url: "#{App.Config.server}/api/ldapGroup"

  model: App.Models.Entry.GroupItem

class App.Models.Entry.TermItem extends Backbone.Model

  idAttribute: "TERM_ID"

  nameAttribute: 'TEXT'

  urlRoot: "#{App.Config.server}/api/term"
class App.Models.Entry.Term extends App.Models.Analysis.Term

class App.Models.Entry.FormItem extends App.Models.Analysis.FormItem
class App.Models.Entry.Form extends App.Models.Analysis.Form

class App.Models.Entry.StampItem extends App.Models.Analysis.StampItem
class App.Models.Entry.Stamp extends App.Models.Analysis.Stamp

class App.Models.Entry.TableItem extends App.Models.Analysis.TableItem
class App.Models.Entry.Table extends App.Models.Analysis.Table

class App.Models.Entry.TableConditionItem extends App.Models.Analysis.TableConditionItem

  urlRoot: "#{App.Config.server}/api/etTableCondition"

class App.Models.Entry.TableCondition extends App.Models.Analysis.TableCondition

class App.Models.Entry.GraphicItem extends App.Models.Analysis.GraphicItem
class App.Models.Entry.Graphic extends App.Models.Analysis.Graphic

class App.Models.Entry.TextObjectItem extends App.Models.Analysis.TextObjectItem
class App.Models.Entry.TextObject extends App.Models.Analysis.TextObject

class App.Models.Entry.SystemTextObjectItem extends App.Models.Analysis.TextObjectItem

  idAttribute: "TEXT_OBJECT_ID"

  type: "system_text_object"

  urlRoot: "#{App.Config.server}/api/textObject"

  islock: (o) ->
    o = action: o if _.isString o

    o.type = 'text_object'
    super o

class App.Models.Entry.SystemTextObject extends App.Common.BackbonePagination

  model: App.Models.Entry.SystemTextObjectItem

  initialize: (o) ->
    super
    # TODO: хардкод выпилить на бекенде;
    @entry =
      url  : "textObject/system"
      type : "system_text_object"

class App.Models.Entry.TextObjectPatternItem extends App.Models.Analysis.TextObjectPatternItem
class App.Models.Entry.TextObjectPattern extends App.Models.Analysis.TextObjectPattern

class App.Models.Entry.FingerprintItem extends App.Models.Analysis.FingerprintItem
class App.Models.Entry.Fingerprint extends App.Models.Analysis.Fingerprint

class App.Models.Entry.FiletypeItem extends Filetype.Model

  sync: (type, model, options) ->
    model = App.request('bookworm', 'filetype').get(model.id)
    if model
      options.success model.toJSON()
    else
      options.error @

  islock: ->
    helpers.islock type: 'file'

  getItem: ->
    title        : @getName()
    key          : @id
    extraClasses : '_noIcon'
    data         : @toJSON()

class App.Models.Entry.Filetype extends Filetype.Collection

class App.Models.Entry.File extends Filetype.Collection

  config: ->
    debugLevel : 0
    extensions : []

  get: (id) ->
    model = super
    model = @format.get id unless model
    model

  initialize: ->
    super
    @format = new App.Models.Entry.Fileformat App.request('bookworm', 'fileformat').toJSON()

  getItems: ->
    _.each super, (item) =>
      filtered = @format.where type_ref: item.key
      filtered = _.map filtered, (model) -> model.getItem()
      item.children = filtered

class App.Models.Entry.FileformatItem extends App.Common.ModelTree

  idAttribute: "format_id"

  urlRoot: "#{App.Config.server}/api/Bookworm/Formats"

  nameAttribute: "name"

  sync: (type, model, options) ->
    model = App.request('bookworm', 'fileformat').get(model.id)
    if model
      options.success model.toJSON()
    else
      options.error @

  islock: ->
    helpers.islock type: 'file'

  getItem: ->
    title        : @getName()
    key          : @id
    extraClasses : '_noIcon'
    data         : @toJSON()

class App.Models.Entry.Fileformat extends App.Common.CollectionTree

  model: App.Models.Entry.FileformatItem

class App.Models.Entry.UserItem extends Backbone.Model

  idAttribute: "USER_ID"

  nameAttribute: "USERNAME"

  urlRoot: "#{App.Config.server}/api/user"

  results: (model) ->
    return disabled: true unless model.EMAIL
    null

class App.Models.Entry.User extends Backbone.Collection

  model: App.Models.Entry.UserItem

class App.Models.Entry.SharepointItem extends Backbone.LocalModel

  type: 'sharepoint'

  sync: (type, model, options) ->
    arr = model.id.split '@'
    options.success
      SERVER : arr[0]
      PATH   : arr[1]

  validation:
    SERVER : required: true

class App.Models.Entry.Sharepoint extends App.Common.BackboneLocalPagination

  model: App.Models.Entry.SharepointItem

  config: ->
    default:
      sortCol   : "NAME"
      sortable  : false
      draggable : false
      checkbox  : false

    columns: [
      id      : "ID"
      name    : App.t 'global.server'
      field   : "ID"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter: (row, cell, value, columnDef, dataContext) ->
        dataContext.get('NAME').split('@')[0]
    ,
      id      : "NAME"
      name    : App.t 'global.path'
      field   : "NAME"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter: (row, cell, value, columnDef, dataContext) ->
        dataContext.get('NAME').split('@')[1]
    ,
      id      : "remove"
      name    : ""
      field   : "remove"
      width   : 40
      resizable : false
      cssClass  : "center"
      formatter : (row, cell, value, columnDef, dataContext) ->
        id = dataContext.id
        "<i class='[ icon _delete _sizeSmall ]' data-action='removeItem' data-id='#{id}'></i>"
    ]

class App.Models.Entry.ShareItem extends Backbone.LocalModel

  type: "share"

  sync: (type, model, options) ->
    arr = model.id.split '@'
    options.success
      WORKSTATION : arr[0]
      PATH    : arr[1]

  validation:
    WORKSTATION : required: true

class App.Models.Entry.Share extends App.Common.BackboneLocalPagination

  model: App.Models.Entry.ShareItem

  config: ->
    default:
      sortCol   : "NAME"
      sortable  : false
      draggable : false
      checkbox  : false

    columns: [
      id      : "ID"
      name    : App.t 'global.workstation'
      field   : "ID"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter: (row, cell, value, columnDef, dataContext) ->
        dataContext.get('NAME').split('@')[0]
    ,
      id      : "NAME"
      name    : App.t 'global.path'
      field   : "NAME"
      resizable : true
      sortable  : true
      minWidth  : 150
      formatter: (row, cell, value, columnDef, dataContext) ->
        dataContext.get('NAME').split('@')[1]
    ,
      id      : "remove"
      name    : ""
      field   : "remove"
      width   : 40
      resizable : false
      cssClass  : "center"
      formatter : (row, cell, value, columnDef, dataContext) ->
        id = dataContext.id
        "<i class='[ icon _delete _sizeSmall ]' data-action='removeItem' data-id='#{id}'></i>"
    ]

class App.Models.Entry.DomainItem extends Backbone.LocalModel

class App.Models.Entry.MailDomainItem extends App.Models.Entry.DomainItem

class App.Models.Entry.Domain extends App.Common.BackboneLocalPagination

  model: App.Models.Entry.DomainItem

class App.Models.Entry.MailDomain extends App.Models.Entry.Domain

  model: App.Models.Entry.MailDomainItem

class App.Models.Entry.ContactItem extends Backbone.LocalModel

  t: (key, options = {}) ->
    if options.context is 'type'
      item = App.request('bookworm', 'contact').findWhere mnemo: key
      return item.getName() if item
    else if options.context is 'title'
      return @get 'name'
    else
      super

class App.Models.Entry.Contact extends App.Common.BackboneLocalPagination

  model: App.Models.Entry.ContactItem

class App.Models.Entry.ResourceItem extends Backbone.Model

  idAttribute: "LIST_ID"

  urlRoot: "#{App.Config.server}/api/systemList"

class App.Models.Entry.Resource extends App.Common.BackbonePagination

  model: App.Models.Entry.ResourceItem

  url: "#{App.Config.server}/api/systemList"

  config: ->
    config = super
    config.columns.pop()
    config

class App.Models.Entry.TagItem extends Backbone.Model

  idAttribute: "TAG_ID"

  urlRoot: "#{App.Config.server}/api/tag"

class App.Models.Entry.Tag extends App.Common.BackbonePagination

  model: App.Models.Entry.TagItem

  url: "#{App.Config.server}/api/tag"

class App.Models.Entry.StatusItem extends Backbone.Model

  idAttribute: "IDENTITY_STATUS_ID"

  urlRoot: "#{App.Config.server}/api/ldapStatus"

class App.Models.Entry.Status extends App.Common.BackbonePagination

  model: App.Models.Entry.StatusItem

  url: "#{App.Config.server}/api/ldapStatus"

class App.Models.Entry.PerimeterItem extends Backbone.Model

  idAttribute: "PERIMETER_ID"

  urlRoot: "#{App.Config.server}/api/perimeter"

class App.Models.Entry.Perimeter extends App.Common.BackbonePagination

  model: App.Models.Entry.PerimeterItem

  config: ->
    config = super
    config.columns.pop()
    config

class App.Models.Entry.PersonItem extends Backbone.Model

  idAttribute: "PERSON_ID"

  type: 'person'

  urlRoot: "#{App.Config.server}/api/ldapPerson"

  display_attr: 'DISPLAY_NAME'

class App.Models.Entry.Person extends App.Common.BackbonePagination

  model: App.Models.Entry.PersonItem

  config: ->
    config = super
    config.columns.pop()
    config

class App.Models.Entry.WorkstationItem extends Backbone.Model

  idAttribute: "WORKSTATION_ID"

  urlRoot: "#{App.Config.server}/api/ldapWorkstation"

class App.Models.Entry.Workstation extends App.Common.BackbonePagination

  model: App.Models.Entry.WorkstationItem

  config: ->
    config = super
    config.columns.pop()
    config

class App.Models.Entry.PolicyItem extends Backbone.Model

  idAttribute: "POLICY_ID"

  urlRoot: "#{App.Config.server}/api/policy"

  can: ->
    return super if type = @get('TYPE')

    return true if helpers.can(type: 'policy_person') or helpers.can(type: 'policy_object')
    false

  islock: ->
    return super type: "policy_#{type.toLowerCase()}" if type = @get('TYPE')

    return true if helpers.islock(type: 'policy_person') and helpers.islock(type: 'policy_object')
    false

class App.Models.Entry.Policy extends App.Common.BackbonePagination

  model: App.Models.Entry.PolicyItem

  initialize: ->
    if helpers.can(type: 'policy_person')
      @filterData = filter: TYPE: 'PERSON' unless helpers.can(type: 'policy_object')
    else
      @filterData = filter: TYPE: 'OBJECT' if helpers.can(type: 'policy_object')

    super
