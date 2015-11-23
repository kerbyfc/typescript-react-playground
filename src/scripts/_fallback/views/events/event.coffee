"use strict"

EventProperties = require "views/events/event_views/event_properties.coffee"
EventFullProperties = require "views/events/event_views/event_details.coffee"

EventTypes =
  email: require "views/events/event_views/eventEmail.coffee"
  im: require "views/events/event_views/eventIm.coffee"
  web: require "views/events/event_views/eventHttp.coffee"
  file: require "views/events/event_views/eventFile.coffee"
  phone: require "views/events/event_views/eventPhone.coffee"
  print: require "views/events/event_views/eventPrint.coffee"
  placement: require "views/events/event_views/eventPlacement.coffee"
  multimedia: require "views/events/event_views/eventMultimedia.coffee"

exports.EmptyEventDetails = class EmptyEventDetails extends Marionette.ItemView

  className: 'sidebar__content eventDetail'

  template: "events/empty_event_details"

exports.EventDetails = class EventDetails extends Marionette.LayoutView

  template: 'events/event_detail'

  className: 'sidebar__content eventDetail'

  templateHelpers: ->
    status: @status

  regions:
    eventProperties                 : '.eventDetail__properties'
    eventContent                    : '.eventDetail__content'

  events:
    "click [data-action-details]"   : "details"

  details: (e) ->
    e.preventDefault()

    @model.loadDetails()
    .done =>
      App.modal.show new EventFullProperties
        title: App.t 'events.events.event_details_title'
        model: @model
        service: @service
    .fail (object) ->
      if object.statusText isnt 'abort'
        App.Notifier.showError({
          title: App.t 'events.conditions.selection'
          # TODO: Добавить локализацию
          text: "Не удалось загрузить данные для обьекта #{@model.id}"
          hide: true
        })

  initialize: (options) ->
    @_rendered = false

  showInfo: ->
    service = @model.get 'service'

    # TODO: Некрасиво, но других вариантов нет. Смотрим,
    # если сервис почта и обьект попал в группу Web-почта, то грузим web вьюху
    if service.get('mnemo') is 'email' and (_.where @model.get('lists'), {LIST_ID: 'EEBF39FBA96B1481E0433D003C0AAC7200000000'}).length
      mnemo = 'web'
    else
      mnemo = service.get 'mnemo'

    content_view = new EventTypes[mnemo]
      model: @model
      service: service

    content_view.parse()
    .then =>
      @render()

      @_rendered = true

      @eventProperties.show new EventProperties
        model: @model
        service: service

      @eventContent.show content_view

  render: ->
    if not @_rendered
      @_rendered =  false
      super()
