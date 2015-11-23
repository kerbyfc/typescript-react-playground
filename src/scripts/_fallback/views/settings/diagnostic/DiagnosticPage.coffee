"use strict"

ModelDiagnosticTaskList = require 'models/settings/DiagnosticTaskList.coffee'
DiagnosticTaskItem = require 'views/settings/diagnostic/DiagnosticTaskItem.coffee'

delayRefresh = require('settings/config.json').diagnostic.delayRefresh

class DiagnosticPage extends Marionette.CompositeView

  template: "settings/diagnostic/DiagnosticPage"

  className: "content"

  ui:
    $form: "form"

  childView: DiagnosticTaskItem

  childViewContainer: "[data-block=loop]"

  events:
    "click [data-action=start]": "onClickStart"

  collectionEvents:
    "add change:status change:file change:error": "onChangeCollection"

  initialize: ->
    @collection = new ModelDiagnosticTaskList

  onRender: ->
    @listenTo(App.Session.user, "message", @onMessageDiagnosticReport.bind(@))

    @_sendRequest()
    @onChangeCollection()

  onClickStart: (e) ->
    e.preventDefault()
    params = _.reduce(@ui.$form.serializeArray(), (res, val) ->
      res[val.name] = (val.value is "true")
      return res
    , {})

    @collection.start(params).then(
      @_onSuccessRequest.bind(@),
      @_onFailDiagnosticReport.bind(@)
    )

  _onFailDiagnosticReport: ->
    App.Notifier.showError
      title: App.t "settings.diagnostic.notify_error__title"
      text:  App.t "settings.diagnostic.notify_error__text"

  onMessageDiagnosticReport: (msg) ->
    if "diagnostic_report" is msg["data"].module
      data = msg["data"].data
      @collection.get(data.id)?.set(data)

  onChangeCollection: ->
    @$el.toggleClass("_in-progress", @collection.hasProgress())

  _abortRequest: ->
    if @timeout
      clearTimeout @timeout
      delete @timeout
    @_xhr and @_xhr.abort()

  _sendRequest: (params) ->
    @_abortRequest()
    xhr = @_xhr = @collection.fetch(params)
    xhr.then @_onSuccessRequest.bind(@), @_onFailRequest.bind(@)
    xhr

  _onSuccessRequest: ->
    if @collection.hasProgress()
      @timeout = setTimeout(@_sendRequest.bind(@), delayRefresh)

  _onFailRequest: ->
    @timeout = setTimeout(@_sendRequest.bind(@), delayRefresh)

module.exports = DiagnosticPage
