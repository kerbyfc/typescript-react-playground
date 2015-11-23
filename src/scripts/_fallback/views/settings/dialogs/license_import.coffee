"use strict"

LicenseViews = require "views/settings/licenses.coffee"

App.module "Settings.Licenses",
  startWithParent: true
  define: (Licenses, App, Backbone, Marionette, $) ->

    App.Views.Licenses ?= {}

    class App.Views.Licenses.LicenseImportDialog extends Marionette.LayoutView

      template: "settings/dialogs/license_import"

      events:
        "click .close_window" : 'close_window'

      ui:
        upload          : ".upload_license"
        result          : ".form__action-result"
        progress        : "progress"
        close_window    : '.close_window'
        label           : '.upload > label'

      regions:
        license_info  : '#license_info'

      templateHelpers: ->
        title: @options.title

      initialize: (options) ->
        @callback = options.callback

      close_window: (e) ->
        e.preventDefault()

        @destroy()


      ###*
       * Show the dialog and await for file upload
      ###
      onShow: ->
        @ui.close_window.hide()

        @ui.upload.on 'change', (e) =>

          # Получаем файл
          file = e.target.files[0]

          reader = new FileReader()

          reader.onload = (e) =>
            try
              @_rawLicense = e.target.result
              @collection.parseLicense @_rawLicense
                .done (data, textStatus, jqXHR) =>
                  @ui.result.hide()
                  @ui.label.html(App.t 'global.add')
                  @_importedLicense = data.data
                  model = new @collection.model @_importedLicense, parse: true
                  model.unset model.idAttribute

                  # We should save raw unparsed license data
                  # cause format could be changed instead of JSON
                  @ui.label.on 'click', (e) =>
                    e?.preventDefault()
                    model.save null,
                      data: @_rawLicense
                      success: =>
                        @collection.add model
                        @callback(model) if @callback
                        @destroy()
                      error: (model, xhr, options) =>
                        @_handleErrorResponse xhr

                      wait: true
                      parse: true

                  @license_info.show new LicenseViews.License(model: model)
                .fail (xhr, textStatus, errorThrown) =>
                  @_handleErrorResponse xhr
            catch
              @_handleError()


          try
            reader.readAsText(file)
          catch
            @_handleError()


      #########################################################################
      # PRIVATE


      ###*
       *  Imported license value object in this dialog, parsed json
       *  @type {Object}
      ###
      _importedLicense : null


      ###*
       * Raw license file
       * @type {String}
      ###
      _rawLicense : null

      ###*
       * Handle xhr for error codes
      ###
      _handleErrorResponse: (xhr) =>
        switch xhr.responseText
          when 'unique'
            @_handleError("settings.license.license_import_unique")

          when 'licserv_not_found'
            @_handleError("settings.license.license_service_unavailable")

          else
            @_handleError()

      ###*
       *  Notify system when error occured and close the dialog
       *  @param {String} i18next key for string about readon of an error
      ###
      _handleError: (errorKey = "settings.license.license_global_import_error") ->
        App.Notifier.showError
          title : App.t("settings.licenses")
          text  : App.t(errorKey)
          hide  : true
        # Close the dialog after notify
        @destroy()
