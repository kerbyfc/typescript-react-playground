"use strict"

module.exports = class FolderContentView extends Marionette.ItemView

  template: "reports/folder"

  className: "content"

  ui:
    name     : "[data-name]"
    personal   : "[data-personal]"
    edit     : "[data-action='edit']"
    delete     : "[data-action='delete']"
    copy     : "[data-action='copy']"
    actions    : "[data-action]"
    personalIcon : "[data-personal-icon]"

  events:
    "click @ui.edit"   : "_edit"
    "click @ui.copy"   : "_copy"
    "click @ui.delete" : "_delete"

  modelEvents:
    "change": "update"

  serializeData: ->
    _.extend super,
      editable: @model.can "edit"

  onShow: ->
    @update()

  _edit: (e) ->
    e.preventDefault()
    App.vent.trigger "nav", "reports/folders/#{@model.id}/edit"

  _copy: (e) ->
    e.preventDefault()
    # TODO: ask if user do not want to copy nested reports
    App.vent.trigger "reports:copy:entity", "folder", @model, withReports: true

  _delete: (e) ->
    e.preventDefault()
    App.vent.trigger "reports:remove:entity", "folder", @model

  update: ->
    @ui.name.text @model.get "DISPLAY_NAME"
    @ui.personal.text App.t "reports.access.personal.#{@model.get 'IS_PERSONAL'}"

    @ui.personalIcon.toggleClass "_hidden", not @model.isPersonal()

    @ui.actions.each (i, el) =>
      $el = $ el
      $el.attr "disabled", =>
        if @model.can $el.data 'action'
          return null
        true
