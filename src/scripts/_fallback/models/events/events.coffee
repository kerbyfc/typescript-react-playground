"use strict"

require "common/backbone-paginator.coffee"

# Event model
#
exports.Model = class Event extends App.Common.ValidationModel

  idAttribute: "OBJECT_ID"

  urlRoot: "#{App.Config.server}/api/object"

  downloadAttach: (content_id) ->
    url_params = $.param
      object_id   : @id
      content_id  : content_id
      download    : 1

    window.location = "#{App.Config.server}/api/object/content?#{url_params}"

  getContent: (content_id, delimiter = '') ->
    return if _.isArray content_id and _.isEmpty content_id

    $.ajax
      type : 'POST'
      data:
        content_id: content_id
      url : "#{App.Config.server}/api/object/content?object_id=#{@id}&delimiter=#{delimiter}"
      dataType: 'text'

  loadDetails: ->
    @fetch
      data:
        extend: 1
      wait: true
      merge: true

  loadContent: ->
    @fetch
      wait: true

  setTags: (tags_id) ->
    @save
      "DATA":
        "TAGS": tags_id
      "ACTION": "set_tags",
        patch: true
        wait: true
        forceUpdate: true

  deleteTags: (tags_id) ->
    @save
      "DATA":
        "TAGS": tags_id
      "ACTION": "remove_tags",
        patch: true
        wait: true
        forceUpdate: true

  parse: (response) ->
    services  = App.request 'bookworm', 'service'
    protocols = App.request 'bookworm', 'protocol'
    events    = App.request 'bookworm', 'event'

    data = response.data or response

    try
      data.PREVIEW_DATA = $.parseJSON(data.PREVIEW_DATA)
    catch
      @log ":parse", "Can't convert PREVIEW_DATA to JSON for object #{data.OBJECT_ID}!"

    data.service  = services.get data.SERVICE_CODE
    data.protocol = protocols.get data.PROTOCOL
    data.event    = events.get data.OBJECT_TYPE_CODE

    # Парсим периметры
    if data.perimeters_routes and data.perimeters_routes.length isnt 0
      for perimeter in data.perimeters_routes
        if perimeter.IN_PERIMETER_ID isnt '0'
          if not data.in_perimeters then data.in_perimeters = []
          data.in_perimeters.push perimeter

        if perimeter.OUT_PERIMETER_ID isnt '0'
          if not data.out_perimeters then data.out_perimeters = []
          data.out_perimeters.push perimeter

    if data.headers
      headers = data.headers

      if headers
        headers = _.groupBy headers, 'NAME'

        if headers.workstation_type?.length
          data.workstation_type = headers.workstation_type[0].VALUE

        data.groupedHeaders = headers

    if data.workstations?.length is 0 and data.workstations_conflicts?.length is 0
      if data.workstations_keys?.length
        data.workstations = [_.min data.workstations_keys, (workstation) -> parseInt(workstation.KEY_PRIORITY, 10)]
    else
      if data.workstations_conflicts?.length > 0
        data.workstations = _.merge data.workstations, data.workstations_conflicts

    data

exports.Collection = class Events extends App.Common.BackbonePagination

  model: exports.Model

  pageSizes: [10, 50, 100, 300]

  paginator_core:
    url: ->
      url = "#{App.Config.server}/api/object?start=#{@currentPage * @perPage}&limit=#{@perPage}"

      if @filter
        url = url + "&" + $.param(@filter)
      if @sortRule
        sort_key = _.keys(@sortRule.sort)[0]

        if sort_key in [
          'recipients',
          'senders',
          'workstations'
        ]
          sort = {}
          sort[sort_key + '.KEY'] = @sortRule.sort[sort_key]
          @sortRule = sort: sort

        if sort_key in [
          'policies',
          'tags',
          'lists'
        ]
          sort = {}
          sort[sort_key + '.DISPLAY_NAME'] = @sortRule.sort[sort_key]
          @sortRule = sort: sort

        url = url + "&" + $.param(@sortRule)
      if @query
        url = url + "&" + $.param(@query)

      if @merge_with
        for elem in @merge_with
          url = url + "&merge_with[]=" + elem

      return url
    dataType: "json"

  paginator_ui:
    firstPage: 0
    currentPage: 0
    perPage: 50


  exportEvents: (data) ->
    $.ajax("#{App.Config.server}/api/object/report",
      contentType: "application/json"
      type: "POST"
      data: JSON.stringify(data))

  sortCollection: (args) ->
    if args.field in [
      'recipients',
      'senders',
      'workstations'
    ]
      field = "#{args.field}_keys_all.KEY"
    else if args.field in [
      'policies',
      'tags',
      'lists'
    ]
      field = "#{args.field}.DISPLAY_NAME"
    else
      field = args.field


    # Формируем параметры запроса
    data = {}
    data.sort = {}
    data.sort[field] = args.direction

    @sortRule = data

    @fetch
      reset: true
