"use strict"

require "views/controls/list.coffee"
require "views/controls/tree.coffee"
require "models/entry.coffee"
require "views/controls/grid.coffee"

App.Views.Entry ?= {}

class App.Views.Entry.Share extends App.Views.Controls.FormList

  islock: -> false

  serialize: ->
    data = super
    data.ID   = data.WORKSTATION + '@' + data.PATH
    data.TYPE = "share"
    data.NAME = data.WORKSTATION

    data.NAME += "@#{data.PATH}" if data.PATH
    data

class App.Views.Entry.Contact extends App.Views.Controls.FormList

  islock: -> false

  ext: ->
    App.request('bookworm', 'contact').map (item) -> item.get('mnemo')

class App.Views.Entry.Domain extends App.Views.Controls.FormList

  islock: -> false

  ext: [
    "url"
    "domain"
  ]

class App.Views.Entry.MailDomain extends App.Views.Controls.FormList

  islock: -> false

  ext: [
    "domain"
  ]

class App.Views.Entry.Sharepoint extends App.Views.Controls.FormList

  islock: -> false

  serialize: ->
    data = super
    data.ID   = data.SERVER + "@" + data.PATH
    data.TYPE = "sharepoint"
    data.NAME = data.SERVER

    if data.PATH
      data.NAME += "@" + data.PATH
    data

class App.Views.Entry.Tag extends App.Views.Controls.Grid

class App.Views.Entry.Status extends App.Views.Controls.Grid

class App.Views.Entry.Resource extends App.Views.Controls.Grid

class App.Views.Entry.Category extends App.Views.Controls.FancyTree
  className: 'analysis_category'

class App.Views.Entry.Catalog extends App.Views.Controls.FancyTree
  className: 'analysis_category'

class App.Views.Entry.Fingerprint extends App.Views.Controls.Grid

class App.Views.Entry.Document extends App.Views.Controls.Grid

class App.Views.Entry.Form extends App.Views.Controls.Grid
class App.Views.Entry.Stamp extends App.Views.Controls.Grid
class App.Views.Entry.Table extends App.Views.Controls.Grid
class App.Views.Entry.Graphic extends App.Views.Controls.Grid

class App.Views.Entry.TextObjectPattern extends App.Views.Controls.Grid
class App.Views.Entry.TextObject extends App.Views.Controls.Grid
class App.Views.Entry.SystemTextObject extends App.Views.Controls.Grid
class App.Views.Entry.Policy extends App.Views.Controls.Grid

class App.Views.Entry.Person extends App.Views.Controls.Grid
class App.Views.Entry.Role extends App.Views.Controls.Grid
class App.Views.Entry.Scope extends App.Views.Controls.Grid

class App.Views.Entry.Perimeter extends App.Views.Controls.Grid

class App.Views.Entry.Workstation extends App.Views.Controls.Grid

class App.Views.Entry.Group extends App.Views.Controls.Tree
  config:
    locale          : App.t('organization', { returnObjectTrees: true })
    draggable       : false
    selectMode      : 2
    checkbox        : true
    data_key_path   : "ID_PATH"
    dataKeyTitle    : "grouppath"
    dataKeyField    : "GROUP_ID"
    dataLoadField   : "ID_PATH"
    dataChildsField : "childsCount"
    dataParentField : "parents"
    dataTextField   : "DISPLAY_NAME"
    dataIconField   : (group_data) ->
      if group_data.GROUP_TYPE is "adRoot"
        "server"
      else if (
        group_data.GROUP_TYPE is "adGroup"  and
        group_data.SOURCE is "dd"
      )
        group_data.SOURCE
      else
        group_data.GROUP_TYPE
    icons:
      "ad"          : "icon _sizeSmall _folderAd"
      "adGroup"     : "icon _sizeSmall _folderAd"
      "adDomain"    : "icon _sizeSmall _server"
      "adOU"        : "icon _sizeSmall _orgUnit"
      "adContainer" : "icon _sizeSmall _folder"
      "dd"          : "icon _sizeSmall _folderDd"
      "server"      : "icon _sizeSmall _server"
      "tmGroup"     : "icon _sizeSmall _folderTm"
      "tmRoot"      : "icon _sizeSmall _folderTm"

class App.Views.Entry.File extends App.Views.Controls.FancyTree

  template: 'controls/entry/file_format'

  ext: [
    "fileformat"
    "filetype"
  ]

  ui: ->
    _.extend super,
      MIN       : "[name=MIN]"
      MAX       : "[name=MAX]"
      ENCRYPTED : "[name=ENCRYPTED]"

  events: ->
    _.extend super,
      "change [name=ENCRYPTED]": ->
        @onChange()

      "keypress [name=MIN],[name=MAX]": (e) ->
        if e.currentTarget.value.length >= 20 or e.charCode < 48 or e.charCode > 57
          e.preventDefault()

      "blur [name=MIN]": ->
        @ui.MAX.val @ui.MIN.val() if +@ui.MIN.val() > +@ui.MAX.val()
        @onChange()

      "blur [name=MAX]": ->
        @ui.MIN.val @ui.MAX.val() if +@ui.MIN.val() > +@ui.MAX.val()
        @onChange()

  onChange: (e) ->
    @trigger "change:data", @

  onRender: ->
    if @options.data.length
      data =
        MIN       : @options.data[0].MIN
        MAX       : @options.data[0].MAX
        ENCRYPTED : @options.data[0].ENCRYPTED

      Backbone.Syphon.deserialize @, data

  get: ->
    data = @serialize()

    _.map super, (item) ->
      item.TYPE = if item.content.format_type_id then "filetype" else "fileformat"
      item.MIME_TYPE = item.content.mime_type
      item.ENCRYPTED = data.ENCRYPTED if data.ENCRYPTED
      item.MIN = +data.MIN if data.MIN
      item.MAX = +data.MAX if data.MAX
      item
