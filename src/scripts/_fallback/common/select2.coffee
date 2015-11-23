"use strict"

helpers = require "common/helpers.coffee"
style   = require "common/style.coffee"
entry   = require "common/entry.coffee"

_innerSeparator = "::"
_outerSeparator = "||"

module.exports =
  set: ($el, options) ->
    local = if options.local then options.local.split "," else []

    if options.server
      # Проверяем на наличие прав на просмотр сущностей
      options.server = _.filter options.server.split(','), (item) ->
        entry.can type: item

      all = options.server.concat local
      options.server = options.server.join ','
    else
      all = _.clone local

    isSingle = all.length is 1

    options.minimumInputLength = if _.isUndefined options.minimumInputLength then 1 else +options.minimumInputLength

    opt =
      multiple        : true
      tokenSeparators : []
      separator       : _outerSeparator
      createSearchChoice: (term, data) ->
        if local?.length
          _.each @opts.local.split(','), (key) ->
            pattern = helpers.patterns[key]
            _data =
              TYPE : key
              NAME : _.trim term
              ID   : _.trim term

            if pattern
              if pattern.test(term) and _.indexOf(local, key) isnt -1
                data.push _data
            else
              data.push _data

        if data.length is 1 then data[0] else null

      ajax:
        url         : "#{App.Config.server}/api/search?scopes=#{options.server}"
        dataType    : 'json'
        quietMillis : 500

        data: (term, page) -> query: term

        results: (data, page) ->
          data = data.data
          result = []
          _.each data, (val, key) ->
            val = _.map val, (item) ->
              config = entry.getConfig item

              # TODO: впилил из за бекенда, выпилить когда реализуют поддержку прав
              model = new config.model item
              return if model.islock type: config.type

              _filter = content: item
              _.extend _filter, results(item) if results = config.model::results
              _.extend entry.getData(item), _filter
            val = _.compact val

            result = _.union result, val

          results: result

      id: (e) -> "#{e.TYPE}#{_innerSeparator}#{e.ID}#{_innerSeparator}#{e.NAME}"

      # formatResultCssClass: (e) ->

      # transformVal: (val) ->

      formatResult: (e) ->
        entry.add e.content if e.content

        Marionette.Renderer.render "controls/select2/result",
          _.extend e,
            server : App.Config.server
            isVisibleLabel : options.isAlwaysVisibleLabel or not isSingle

      formatSelection: (e) ->
        _data = entry.get e.TYPE, e.ID
        Marionette.Renderer.render "controls/select2/selection",
          _.extend e, options: _data

      initSelection: (element, callback) ->
        data  = []
        value = element.val().split _outerSeparator

        $ value
        .each ->
          item = @split _innerSeparator
          _data =
            id   : @
            ID   : item[1] or item[2]
            TYPE : item[0]
            NAME : item[2]

          data.push _data
        element.val ''
        callback data

    if options.query
      opt.query = options.query

    if not options.server
      delete opt.ajax
      opt.query = (query) -> query.callback results: []

    _.extend opt, options

    $el.select2 opt

  innerSeparator: _innerSeparator

  outerSeparator: _outerSeparator

  setVal: (val) ->
    val = _.map val, (item) -> "#{item.TYPE}#{_innerSeparator}#{item.ID}#{_innerSeparator}#{item.NAME}"

    val.join _outerSeparator

  getVal: (val, onlydata) ->
    return null if not val
    val = val.split _outerSeparator
    val = _.map val, (item) ->
      data = item.split _innerSeparator

      _data =
        TYPE : data[0]
        ID   : data[1]
        NAME : data[2]

      _data.content = entry.get data[0], data[1] unless onlydata
      _data
