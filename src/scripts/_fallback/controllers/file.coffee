"use strict"

bookworm = require "controllers/bookworm.coffee"
Filetype = require "models/lists/filetype.coffee"
Fileformat = require "models/lists/fileformat.coffee"
FileformatView = require "views/file/fileformat.coffee"
FiletypeView = require "views/file/filetype.coffee"

require "views/bookworm/bookworm_unactive.coffee"

App.module "File",
  startWithParent: false

  define: (Module, App) ->

    class Controller extends Marionette.Controller

      unactive: ->
        App.Layouts.Application.sidebar._ensureElement()
        App.Layouts.Application.sidebar.$el.hide()

        App.Layouts.Application.content.show new App.Bookworm.BookwormUnactive

      active: (type, id) ->
        types = new Filetype.Collection
        view  = new FiletypeView.Filetype collection: types
        App.Layouts.Application.sidebar.show view
        types.fetch
          reset : true
          wait  : true
          success: ->
            if type
              view.select types.get type
            else
              App.Layouts.Application.content.show new FileformatView.FileEmpty

        collection = new Fileformat.Collection

        isNotSelected = true

        @listenTo types, 'select', (section, id) ->
          return collection.reset() unless section

          if isNotSelected
            App.Layouts.Application.content.show new FileformatView.Fileformat collection: collection
            isNotSelected = false

          collection.section = section
          collection.trigger 'search:clear'
          collection.reset _.where(App.request('bookworm', 'fileformat').toJSON(), type_ref: section.id)

      index: ->
        prefix = if bookworm.active then "" else "un"
        @["#{prefix}active"] arguments...

        bookworm.on 'bookworm:unactive', @unactive
        bookworm.on 'bookworm:active', @active

    # Initializers And Finalizers
    # ---------------------------
    Module.addInitializer ->
      App.Controllers.File = new Controller

    Module.addFinalizer ->
      App.Controllers.File.destroy()
      delete App.Controllers.File
