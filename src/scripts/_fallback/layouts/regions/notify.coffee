class NotifyRegion extends Marionette.Region

  el: "#notify"

  show: ->
    super

    collection = @currentView.collection

    @listenTo collection, "reset", ->
      @$el.hide() unless collection.length

    @listenTo collection, "add", ->
      @$el.show() if collection.length

    # TODO: на текущий момент нет четкого понимания того какие события должны триггаться,
    # когда данные приходят в сокет. После выработки общей концепции, рефакторить
    @listenTo App.Session.user, "message:export", @onSocketEvent
    @listenTo App.Session.user, "message:import", @onSocketEvent

    @$form = $ Marionette.Renderer.render "controls/form/upload"
    .appendTo 'body'

  onSocketEvent: (data) ->
    # TODO: выработать совместо с бекендом единые статусы при всех операциях,
    # которые приходят в сокет (если export -> exported, import -> imported и т.д.)
    action = data.type
    module = data.module

    state  = if data.status is 'success' then "#{action}ed" else data.status

    model = @get().findWhere
      action : data.type
      module : data.module

    if model
      model.set
        percent : data.percent
        state   : state
    else
      model = @add
        action  : action
        name    : App.t "select_dialog.#{action}", context: module
        module  : module
        percent : data.percent or 0
        state   : state

    if state is 'error' and data.message
      model.set error: App.t("form.error.#{data.message}")

  send: (o, entry) ->
    self = @

    @$form.fileupload 'send', o
    .done (result) ->
      data  = result.data
      return unless data
      if @cid
        model = self.get @cid
      else
        model = self.add o.options

      model.set
        key  : data.key
        name : data.name

    .fail (xhr, state, message) ->
      if @options.type in ['export', 'import']
        model = self.get().findWhere
          action : @options.type
          module : @options.module
      else if @cid
        model = self.get @cid
      else
        model = self.add o.options

      type = model.get 'type'

      error = xhr.responseJSON?.error or xhr.responseText

      # TODO: ждем единой для всего бекенда реализации ошибок
      # после этого рефакторить
      errorOptions =
        context : 'error'
        type    : type
        name    : 'misc'

      switch error
        when 'bad_extension'
          error = App.t "form.error.not_allowed_file_extension"
        when 'file_not_saved'
          error = App.t "form.error.file_not_saved"
        when 'not_match', 'resolution_too_low', 'too_big_size', 'too_small_size', 'not_allowed_file_extension'
          error = model.t "#{error}", errorOptions
        when 'duplicate', 'not_unique_field'
          dup  = xhr.responseJSON.models[0]
          e2c  = dup.category
          type = model.get 'type'

          categories = _.map e2c, (link) -> link.DISPLAY_NAME
          context = if categories.length > 1 then 'in_many' else 'in'
          error = model.t "contstraint_violation2",
            item     : App.t "select_dialog.#{type}"
            section  : App.t("select_dialog.group_#{type}", context: context).toLowerCase()
            sections : categories.join ', '
            context  : 'error'
            type     : type

        else
          error = model.t 'undefined_error', errorOptions

      model.set
        state : 'error'
        error : error

  fileupload: (options) ->
    options = _.extend
      dataType               : 'json'
      method                 : 'post'
      limitConcurrentUploads : 8
      pasteZone              : null
    , options

    $input = @$form.find 'input'

    if options.acceptTypes
      $input.attr 'accept', options.acceptTypes
    else
      $input.removeAttr 'accept'

    if options.multiple
      $input.attr 'multiple', ''
    else
      $input.removeAttr 'multiple'

    @$form.fileupload options

    $input.trigger 'click'

  get: (id) ->
    collection = @currentView.collection
    return collection unless id
    collection.get id

  reset: ->
    @currentView.collection.reset arguments...

  add: (data) ->
    collection = @currentView.collection
    unless _.isArray data
      model = new collection.model data,
        collection: collection

    # TODO: в дальнейшем выработать совместно с дизайнером,
    # модель поведения при экспорте и импорте
    if data.action is 'export' or
    data.action is 'import'
      models = collection.findWhere
        module : data.module
        action : data.action

      if models
        models.set data
        return models

    collection.add(model or data)
    model or collection


module.exports = NotifyRegion
