"use strict"

module.exports = class ChangePasswordDialog extends Marionette.ItemView

  template: "settings/users_and_roles/change_password"

  events:
    "click ._success": "save"

  templateHelpers: ->
    title: @options.title

  save: (e) ->
    e?.preventDefault()

    data = Backbone.Syphon.serialize @

    @model.save data,
      wait: true
      success: (model, collection, options) =>
        if @noty
          @noty.remove()

        @destroy()
        @options.callback() if @callback

      error: (model, xhr, options) ->
        App.Notifier.showError
          title: App.t 'settings.users_tab'
          text: xhr.responseText
          hide: true

  onDestroy: ->
    Backbone.Validation.unbind(@)

  onShow: ->
    Backbone.Validation.bind(@)

    Backbone.Syphon.deserialize @, @model.toJSON()
