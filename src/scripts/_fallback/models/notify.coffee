"use strict"

class App.Models.NotifyItem extends Backbone.Model

  idAttribute: 'key'

  nameAttribute: 'name'

  defaults: ->
    type      : "" # тип сущности ex: fingerprint
    action    : "create" # ex: "import", "export", "update" etc
    name      : ""
    state     : ""
    sectionId : ""
    id        : ""
    module    : ""
    percent   : 0
    size      : 0

class App.Models.Notify extends Backbone.Collection

  model: App.Models.NotifyItem
