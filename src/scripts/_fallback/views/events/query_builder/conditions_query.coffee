"use strict"

require "moment_ru"
require "bootstrap.multiselect"
require "bootstrap.datetimepicker"
require "bootstrap.datetimepicker.ru"

require "models/lists/fileformat.coffee"
require "models/lists/filetype.coffee"

Selection = require "models/events/selections.coffee"
QueryBuilderBase = require "views/events/query_builder/query_builder_base.coffee"

conditions = require "settings/conditions"

module.exports = class ConditionsQueryParams extends App.Helpers.virtual_class(
  QueryBuilderBase
  Marionette.ItemView
)

  template: "events/query_builder/conditions_query"

  templateHelpers: ->
    USER_ID    : @model.get 'USER_ID'
    mode       : @model.get('QUERY').mode or 'lite'
    conditions : @options.conditions or conditions
    exclude    : @options.exclude or []

  defaults:
    conditions: conditions

  behaviors: ->
    @data = {}

    query = @options.model.get('QUERY')

    @condition_model = new Selection.TreeNode query.data

    @data = _.merge @data, @parseQuery query.data.children

    Form:
      syphon         : @data
      listen         : @condition_model
      isAutoValidate : true

  initialize: (options = {}) ->
    @formats = App.request 'bookworm', 'fileformat'

    _.extend @options, _.defaults options, @defaults

  onShow: ->
    @listenTo @, "form:change", _.debounce =>
      @condition_model.trigger 'form:reset'

      data = @serialize()

      condition = @model.get('QUERY')

      @condition_model.resetCondition data
      if @condition_model.isValid()
        condition.data = @condition_model.toJSON()
        @model.set 'QUERY', condition
        @model.trigger 'change:QUERY', @model, @condition_model.toJSON(), {}
        @model.trigger 'change', @model, {}
    , 333

  _crawlerConditionsToggle: (object_type_code = []) ->
    # TODO: убрать копипасту
    if object_type_code.length is 0 or '602A224D9335579214E3188D1D2745DB9F85D500' in object_type_code
      @$('[data-group="crawler_tasks"]').show()

      @$('[name="create_date[start_date]"]').closest('.form__row').show()
      @$('[name="modify_date[start_date]"]').closest('.form__row').show()
    else
      @$('[data-group="crawler_tasks"]').hide()
      @$('[name="create_date[start_date]"]').closest('.form__row').hide()
      @$('[name="modify_date[start_date]"]').closest('.form__row').hide()

      # Сбрасываем input и textarea
      @$('[data-group="crawler_tasks"]').find('input').val('')
      @$('[data-group="crawler_tasks"]').find('textarea').val('')

      # Сбрасываем списки
      @$('[data-group="crawler_tasks"] option:selected').prop 'selected', false
      @$('[data-group="crawler_tasks"] select').multiselect 'rebuild'

      @$('[name="create_date[start_date]"]').val('')
      @$('[name="create_date[end_date]"]').val('')

      @$('[name="modify_date[start_date]"]').val('')
      @$('[name="modify_date[end_date]"]').val('')

  _destinationPathToggle: (object_type_code = []) ->
    if object_type_code.length is 0 or
       _.intersection(object_type_code, [
         '602A224D9335579214E3188D1D2745DB9F85D500'  # crawler
         '1515A7B027DB11E2BBB2EFDB6088709B00000000'  # ftp
         '190D004827DB11E287B1F0DB6088709B00000000'  # External device
       ]).length
      @$('[name="destination_path[value]"]').closest('.form__row').show()
    else
      @$('[name="destination_path[value]"]').closest('.form__row').hide()
      @$('[name="destination_path[value]"]').val('')


  onDomRefresh: ->
    super()

    @_crawlerConditionsToggle(@data.object_type_code)
    @_destinationPathToggle(@data.object_type_code)


    @$el.find('[name="object_type_code[]"]').on 'change', =>
      val = @$el.find('[name="object_type_code[]"]').val()

      @_crawlerConditionsToggle(val)
      @_destinationPathToggle(val)
