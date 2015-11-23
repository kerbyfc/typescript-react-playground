"use strict"

App.module "Bookworm",
  startWithParent: false

  define: (Module, App) ->

    App.Models.Bookworm ?= {}

    class App.Models.Bookworm.FileformatItem extends Backbone.Model

      idAttribute: "format_id"

      nameAttribute: "name"

    class App.Models.Bookworm.FiletypeItem extends Backbone.Model

      idAttribute: "format_type_id"

      nameAttribute: "name"

    class App.Models.Bookworm.ServiceItem extends Backbone.Model

      idAttribute: "service_id"

    class App.Models.Bookworm.ProtocolItem extends Backbone.Model

      idAttribute: "protocol_id"

    class App.Models.Bookworm.EventItem extends Backbone.Model

      idAttribute: "event_id"

    class App.Models.Bookworm.ContactItem extends Backbone.Model

      idAttribute: "contact_type_id"

      nameAttribute: 'name'

    class App.Models.Bookworm.Fileformat extends Backbone.Collection

      model: App.Models.Bookworm.FileformatItem

      url: "#{App.Config.server}/api/bookworm/formats"

      pretty: -> _.groupBy @toJSON(), 'mime_type'

    class App.Models.Bookworm.Filetype extends Backbone.Collection

      model: App.Models.Bookworm.FiletypeItem

      url: "#{App.Config.server}/api/bookworm/FormatTypes"

    class App.Models.Bookworm.Service extends Backbone.Collection

      model: App.Models.Bookworm.ServiceItem

      url: "#{App.Config.server}/api/bookworm/Services"

    class App.Models.Bookworm.Protocol extends Backbone.Collection

      model: App.Models.Bookworm.ProtocolItem

      url: "#{App.Config.server}/api/bookworm/Protocols"

    class App.Models.Bookworm.Event extends Backbone.Collection

      model: App.Models.Bookworm.EventItem

      url: "#{App.Config.server}/api/bookworm/Events"

    class App.Models.Bookworm.Contact extends Backbone.Collection

      model: App.Models.Bookworm.ContactItem

      url: "#{App.Config.server}/api/bookworm/contactType"

exports.collections = [
  App.Models.Bookworm.Fileformat
  App.Models.Bookworm.Filetype
  App.Models.Bookworm.Service
  App.Models.Bookworm.Protocol
  App.Models.Bookworm.Event
  App.Models.Bookworm.Contact
]
