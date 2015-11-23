"use strict"

select2 = require "common/select2.coffee"
formatDate = 'YYYY-MM-DD 00:00:00'

module.exports = class QueryBuilderBase

  filterTemplates: {}

  onDomRefresh: ->

    if @data
      for condition in ['documents', 'policies']
        if @data[condition]?.any
          @$("[name='#{condition}[any]']").prop('checked', 'checked')

          @$("[name='#{condition}[value][]']").prop('disabled', 'disabled')
          @$(".select_#{condition}").prop('disabled', true)

      if @data.text?.raw is 1
        @$el.find('[name="text[search_mode]"]').prop "disabled", true
        @$el.find('[name="text[morphology]"]').prop "disabled", true

    @$el.find('[name="text[raw]"]').on 'change', (e) =>
      if e.currentTarget.checked
        @$el.find('[name="text[search_mode]"]').prop "disabled", true
        @$el.find('[name="text[morphology]"]').prop "disabled", true
      else
        @$el.find('[name="text[search_mode]"]').prop "disabled", false
        @$el.find('[name="text[morphology]"]').prop "disabled", false

    _.each ['documents', 'policies'], (condition) =>
      @$el.find("[name='#{condition}[any]']").on 'change', =>
        elem        = @$("[name='#{condition}[value][]']")
        select_btn  = @$(".select_#{condition}")
        mode        = @$("[name='#{condition}[mode]']")

        elem.select2("val", "")

        if @$el.find("[name='#{condition}[any]']").prop('checked')
          elem.select2('enable', false)
          select_btn.prop('disabled', true)
          mode.prop('disabled', true)

          mode.select2('val', '0')
          if condition is 'documents'
            elem.val("document::any::#{App.t 'events.conditions.any_documents'}").trigger 'change'
          else
            elem.val("policy::any::#{App.t 'events.conditions.any_policies'}").trigger 'change'
        else
          elem.select2('enable', true)
          select_btn.prop('disabled', false)
          mode.prop('disabled', false)

    @$el.find('[data-form-attr-dialog="file"]').on 'click', =>
      @formats      = App.request 'bookworm', 'fileformat'
      @formatTypes  = App.request 'bookworm', 'filetype'

      val = select2.getVal @$el.find('[data-attribute="file_format"]').val()

      if val and val.length
        for value in val
          if value.TYPE is 'filetype'
            format = @formatTypes.where({format_type_id: value.ID})[0]
          else
            format = @formats.where({mime_type: value.ID})[0]

          value.ID = format.id

      modal = if App.modal.currentView then App.modal2 else App.modal
      modal.show new App.Views.Controls.DialogSelect
        action   : "add"
        title    : App.t 'events.conditions.select_file_formats'
        data     : val
        items    : ['file']
        callback : (data) =>
          modal.empty()

          val = _.map data[0], (item) -> "#{item.TYPE}::#{item.MIME_TYPE or item.ID}::#{item.NAME}"

          @$el.find('[data-attribute="file_format"]').val(val.join('||')).trigger "change"

    ##############################################################
    # Формат файла
    ##############################################################
    @$el.find('[data-attribute="file_format"]').select2
      placeholder: App.t 'events.conditions.file_format_placeholder'
      minimumInputLength: 1
      multiple: true
      separator: '||'
      id: (e) -> "#{e.TYPE}::#{e.DATA}::#{e.NAME}"
      query: (query) =>
        data = {results: []}

        @formatTypes = App.request 'bookworm', 'filetype'

        # Ищем по имени
        result = @formats.filter (format) ->
          format.get('name').toLowerCase().indexOf(query.term.toLowerCase()) isnt -1

        result = _.union result, @formatTypes.filter (format) ->
          format.get('name').toLowerCase().indexOf(query.term.toLowerCase()) isnt -1

        result = _.union result, @formats.filter (format) ->
          format.get('extensions').indexOf(query.term.toLowerCase()) isnt -1

        result = _.uniq result

        for res in result
          data.results.push {TYPE: 'filetype', DATA: res.get('mime_type') or res.id, NAME: res.get('name')}

        query.callback data

      formatResult: (data) -> return '<div>' + data.NAME + '</div>'
      formatSelection: (data) -> return '<div>' + data.NAME + '</div>'
      initSelection: (element, callback) ->
        data = []

        for item in element.val().split("||")
          val = item.split('::')

          data.push({
            id: item,
            TYPE: val[0]
            DATA: val[1]
            NAME: val[2]
          })

        element.val('')

        callback(data)

    @options.afterRender? @

  _getFactor: (data) ->
    switch data
      when 'KB'
        1024
      when 'MB'
        1024 * 1024
      when 'GB'
        1024 * 1024 * 1024
      else
        1

  parseQuery: (query) ->
    data = {}

    if query
      for item in query
        if item.category? and item.value
          switch item.category
            when 'object_id'
              data[item.category] = {}
              data[item.category]['value'] = item.value.join(',')
              data[item.category]['mode'] = item.is_negative

            when 'object_header'
              switch item.value.name
                when 'create_date', 'modify_date', 'task_run_date'
                  if item.value.operation is 'between'
                    if item.value.value[0] or item.value.value[1]
                      data[item.value.name] = {}

                    if item.value.value[0]
                      data[item.value.name]['start_date'] = moment.unix(item.value.value[0]).format(formatDate)
                    if item.value.value[1]
                      data[item.value.name]['end_date'] = moment.unix(item.value.value[1]).format(formatDate)

                when 'task_name', 'workstation_type', 'destination_type'
                  data[item.value.name] = item.value.value

            when 'file_size'
              data['file_size'] = {}

              factor1 = @_getFactor(item.size[0])
              factor2 = @_getFactor(item.size[1])

              if item.value[0] isnt null
                data['file_size']['start'] = item.value[0] / factor1

              if item.value[1] isnt null
                data['file_size']['end'] = item.value[1] / factor2

              data['file_size']['ATTACH_SIZE_MIN_TYPE'] = item.size[0]
              data['file_size']['ATTACH_SIZE_MAX_TYPE'] = item.size[1]

            when 'file_format'
              data[item.category] = {}

              if item.value.formats?
                data[item.category]['formats'] = (_.map item.value.formats, (format) ->
                  return "#{format.TYPE}::#{format.DATA}::#{format.NAME}"
                ).join('||')

              if item.value.encrypted?
                data[item.category]['encrypted'] = item.value.encrypted

              data[item.category]['mode'] = item.is_negative

            when 'senders', 'recipients', 'workstations', 'resources', 'tags', 'perimeter_in', 'perimeter_out', 'policies'
              data[item.category] = {}
              data[item.category]['value'] = _.union data[item.category]['value'], _.map item.value, (ident) ->
                #TODO: нужно исправить в политиках на dnshostname и убрать этот костыль тут
                if ident.TYPE is 'dnshostname' then ident.TYPE = 'dns'

                return {
                  ID: ident.DATA
                  TYPE: ident.TYPE
                  NAME: ident.NAME
                }
              data[item.category]['mode'] = item.is_negative

            when 'analysis', 'documents'
              data[item.category] = {}
              data[item.category]['any'] = item.value[0]?.DATA is 'any'
              data[item.category]['value'] = _.union data[item.category]['value'], _.map item.value, (ident) ->
                return {
                  ID: ident.DATA
                  TYPE: ident.TYPE
                  NAME: ident.NAME
                }
              data[item.category]['mode'] = item.is_negative

            when 'violation_level', 'user_decision', 'rule_group_type', 'verdict', \
               'object_type_code', 'service_code', 'protocol', 'workstation_type'
              data[item.category] = item.value

            when 'text'
              data[item.category] = {}
              data[item.category]['value'] = item.value.DATA
              if item.value.mode isnt 'raw'
                data[item.category]['search_mode'] = item.value.mode
              data[item.category]['morphology'] = +item.value.morphology
              data[item.category]['raw'] = if item.value.mode is 'raw' then 1 else 0
              data[item.category]['scope'] = item.value.scope

              data[item.category]['mode'] = item.is_negative

            when 'file_name', 'destination_path'
              data[item.category] = {}
              data[item.category]['value'] = item.value?.join(',')
              data[item.category]['mode'] = item.is_negative

            when 'capture_date'
              if item.value
                data[item.category] = {}

                if item.value.type in ['period', 'from', 'range', 'to']
                  if item.value.period[1]
                    data[item.category]['end_date'] = moment.unix(parseInt(item.value.period[1])).format(formatDate)

                  if item.value.period[0]
                    data[item.category]['start_date'] = moment.unix(parseInt(item.value.period[0])).format(formatDate)
                    if item.value.period[1]
                      item.value.type = 'range'
                    else
                      item.value.type = 'from'
                  else
                    item.value.type = 'to'

                  data[item.category]['interval'] = item.value.type
                else
                  if item.value.type is 'last_days'
                    data[item.category]['interval'] = "last_#{item.value.days}_days"
                  else
                    data[item.category]['interval'] = item.value.type

        else
          data = _.merge data, @parseQuery(item.children)

    return data
