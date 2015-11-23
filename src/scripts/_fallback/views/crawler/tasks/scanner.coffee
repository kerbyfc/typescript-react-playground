"use strict"

module.exports = class ScannerEditForm extends Marionette.ItemView

  template: "crawler/scanners/scanner"

  className: "content"

  ui:
    save    : "[data-action='save']"
    cancel  : "[data-action='cancel']"

  events:
    "click @ui.save"    : "save"
    "click @ui.cancel"  : "cancel"


  templateHelpers: ->
    title: @options.title

  behaviors: ->
    data = @options.model.toJSON()

    parseUrl = data.ExpressdUri.Value.replace("xml://", "").split(':')

    data.ExpressdHost = parseUrl[0]
    data.ExpressdPort = parseUrl[1]

    data.SendManagerTBFSpeed.Value  = data.SendManagerTBFSpeed.Value / 1024
    data.TasksTBFSpeed.Value        = data.TasksTBFSpeed.Value / 1024
    data.FilteredSids.Value         = data.FilteredSids.Value.replace(/;/g, "\n")
    data.SystemFolders.Value        = data.SystemFolders.Value.replace(/;/g, "\n")

    Form:
      listen: @options.model
      syphon: data

  cancel: (e) ->
    e?.preventDefault()

    @options.cancel?()

  save: (e) ->
    e?.preventDefault()

    data = @getData()

    if data.SendManagerTBFSpeed.Value
      data.SendManagerTBFSpeed.Value  = data.SendManagerTBFSpeed.Value * 1024
      data.SendManagerTBFSize         ?= {}
      data.SendManagerTBFSize.Value   = data.SendManagerTBFSpeed.Value

    if data.TasksTBFSpeed.Value
      data.TasksTBFSpeed.Value        = data.TasksTBFSpeed.Value * 1024
      data.TasksTBFSize               ?= {}
      data.TasksTBFSize.Value         = data.TasksTBFSpeed.Value

    data.FilteredSids.Value           = data.FilteredSids.Value.replace(/\n/g, ";")
    data.SystemFolders.Value          = data.SystemFolders.Value.replace(/\n/g, ";")

    data.ExpressdUri =
      Value: "xml://#{data.ExpressdHost}:#{data.ExpressdPort}"

    delete data.ExpressdHost
    delete data.ExpressdPort

    @options.done? data
