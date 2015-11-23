"use strict"

select2 = require "common/select2.coffee"
helpers = require "common/helpers.coffee"
{attr}  = require "common/style.coffee"
entry   = require "common/entry.coffee"
require "backbone.syphon"
require "timepicker"
require "multiselect"
require "bootstrap.multiselect"
require "bootstrap-multiselect-collapsible-groups"

formHelpers         = require "components/form/helpers.coffee"
createFormComponent = require "components/form.coffee"

App.Behaviors.Common ?= {}

class App.Behaviors.Common.Form extends Marionette.Behavior

  defaults:
    # TODO: выработать единые требования для всех компонентов
    # которые используются в ГУИ, вынести все селекторы
    # не использовать переопределение элементов
    # не использовать behaviors: Form: 'select': '' и тд
    'form'           : 'form'
    'select'         : 'select:not([data-form-type="multiselect"]:not([data-form-type="multiselectList"]))'
    'select2'        : '[data-form-type=select2]'
    'multiselect'    : '[data-form-type=multiselect]'
    'time'           : '[data-form-type=time]'
    'datetime'       : '[data-form-type=datetime]'
    'day'            : '[data-form-type=day]'
    'input'          : ':input'
    'for'            : '[for]'
    'submit'         : '[type="submit"],._success,[data-action="save"]'
    'reset'          : ':reset'
    'required'       : '[required]'
    'fieldset'       : 'fieldset'
    'changeDate'     : '[data-ui=changeDate]'
    'elem'           : '.form__elem'
    'row'            : '.form__row'
    'footer'         : '.form__elem,.popup__footer,.sidebar__footer'
    'disabled'       : ['fieldset,select', 'select2', 'submit', 'customDisabled']
    'removeSelect2'  : ['textarea,select', 'select2', 'select']
    'formatDate'     : 'YYYY-MM-DD 00:00:00' # TODO: вынести формат в хелперы
    'isAutoValidate' : false

    component: '[data-form-component]'

  initialize: ->
    if @options.syphon isnt false
      data   = @options.syphon
      listen = @options.listen
      if data is true and listen and listen.deserialize
        data = listen.deserialize()
      @view.data = data

  onRender: ->
    formSelector = @options.form
    if formSelector and formSelector is 'form' and @el.tagName is 'FORM'
      @$form = @$el
    else
      @$form = formHelpers.getEl formSelector, @$el

    if @view.model
      @$form
      .attr 'data-cid', @view.model.cid

    if @options.listen?.islock('edit')
      @getEl('disabled').prop 'disabled', true

    Backbone.Syphon.deserialize @view, @view.data if @view.data

    @getEl 'datetime'
    .datetimepicker
      language         : App.Session.currentUser().get('LANGUAGE')[0..1]
      pick12HourFormat : false
      pickSeconds      : false

  onShow: ->
    self = @

    @$form.on "submit", (e) =>
      e.preventDefault()
      @view.trigger "form:submit", e

    if @options.listen
      @listenTo @options.listen , "invalid"    , @invalid
      @listenTo @options.listen , "error"      , @onError
      @listenTo @options.listen , "form:reset" , @reset
      @listenTo @options.listen , "sync"       , @onSync
      @listenTo @options.listen , "request"    , @onRequest

    @getEl 'component'
    .each (i, node) =>
      createFormComponent node, @

    # TODO: совместно с выработкой требований для компонентов, используемых в ГУИ
    # вынести навешивание jquery компонентов и реализовать ввиде отдельных хелперов

    @getEl 'select2'
    .each (i, node) ->
      $el = $(node)
      options =
        server            : $el.data 'form-server'
        local             : $el.data 'form-local'
        minimumInputLength: $el.data('form-minimum-input-length')
      if $el.prop('maxlength') and +$el.prop('maxlength') > 0
        options.maximumInputLength = $el.prop('maxlength')
      select2.set $el, options

    # TODO: впилить инициализацию .spinner
    # прокидывать disabled, если не хватате прав

    @getEl 'time'
    .timepicker showMeridian: false

    @getEl 'multiselect'
    .each (i, node) ->
      $el = $(node)

      $el.multiselect
        buttonClass                 : 'btn btn-link'
        enableClickableOptGroups    : true
        maxHeight                   : 350
        buttonTitle                 : -> ""
        enableHTML                  : true
        groupClass                  : "form__checkbox"
        defaultLabel                : $el.attr('data-default-label')
        enableCollapsibleOptGroups  : $el.attr('collapsible-groups')
        templates:
          li: ->
            $li = $('<li><a tabindex="0"><label></label></a></li>')

            if @options.multiple
              $('label', $li).addClass('form__checkbox')

            if @options.enableCollapsibleOptGroups
              $('label', $li).addClass('subgroup')

            $li.prop('outerHTML')

        optionLabel: (element) ->
          label = $.fn.multiselect.Constructor.prototype.defaults.optionLabel(element)

          if @multiple
            label = '<span></span>' + label

          label

        buttonText: (options, select) ->
          if options.length is 0
            return "#{@defaultLabel or App.t('global.none_selected')} <b class='caret'></b>"
          else
            selected = ''
            options.each ->
              label = if ($(@).attr('label') isnt undefined) then $(@).attr('label') else $(@).text()

              selected += label + ', '

            return selected.substr(0, selected.length - 2) + ' <b class="caret"></b>'

    @getEl 'for'
    .each (i, node) =>
      $el = @getElByName $(node).attr 'for'

      if $el.length is 1
        $el.attr 'autocomplete', 'off'
        id  = $el.attr('id') or "#{@view.cid}_#{$el.attr('name')}"
        $el.attr 'id', id
        $(node).attr 'for', id

    @getEl "select"
    .select2
      minimumResultsForSearch: 10
      escapeMarkup: (m) -> m
      formatResult: (options) ->
        # TODO: вынести разметку в темплейты
        data = $(options.element).data()
        str = options.text
        if data.iconPath
          str = "<img src='#{App.Config.server}/img/icon/#{data.iconPath}' width=24 height=24>#{str}"
        else if data.iconClass
          str = "<i class='#{data.iconClass}'></i>#{str}"
        str

      formatSelection: (options) ->
        data = $(options.element).data()
        str = options.text
        if data.iconPath
          str = "<img src='#{App.Config.server}/img/icon/#{data.iconPath}' width=24 height=24>#{str}"
        else if data.iconClass
          str = "<i class='#{data.iconClass}'></i>#{str}"
        str

    @$form.find '[data-form-autofocus=true]' # TODO: пересмотреть атрибут
    .focus().select()

    @$form.find '[data-form-entry]'
    .on "click", (e) =>
      e.preventDefault()
      $el = $ e.currentTarget
      data = $el.data()
      input = $el.closest @options.elem
      .find 'textarea'

      items = data.formEntry.split ','
      items = _.filter items, (item) ->
        entry.can type: item

      unless items.length
        # если нет прав, выводим сообщение об ошибке
        return if +$el.data('state') is 2

        App.Notifier.showError
          title : App.t "menu.#{helpers.getCurrentModuleName()?.toLowerCase()}"
          text  : App.t "form.error.not_access", context: 'show'
          hide  : true

        $el
        .attr
          'data-content'    : App.t "form.error.not_access", context: 'show'
          'data-popover-el' : ''
          'data-state'      : 2
      else
        modal = if App.modal.currentView then App.modal2 else App.modal
        modal.show new App.Views.Controls.DialogSelect
          action   : "add"
          title    : data.formTitle
          data     : select2.getVal input.val()
          items    : items
          callback : (data) ->
            modal.empty()
            input
            .val select2.setVal data[0]
            .trigger "change"

    # TODO: уточнить у Валеры отображение таких элементов
    # и в случае ненадобности выпилить
    @getEl "required"
    .each (i, node) =>
      $el = $ node
      container = $el.closest @options.elem
      # TODO: вынести разметку в темплейты
      container.append '<i>'

    @view.isChanged = false

    @defaultSubmitDisabled = @getEl "submit"
    .prop "disabled"

    if @options.syphon
      @defaultData = @view.serialize() if @options.syphon

      @getEl 'datetime'
      .on "changeDate", => @onChange arguments...

      @getEl "input"
      .on "keyup change", => @onChange arguments...

      @listenTo @options.listen , "change", @onChange
      @listenTo @view , "change", @onChange

      @relation = _.result @options.listen, 'relation'

      if @relation
        _.each _.keys(@relation), (key) =>
          @setRelation key, @defaultData[key]

    @view.trigger 'behavior:Form:onShow'

  onChange: (e) ->
    data = @view.serialize()

    if e
      $el = $ e.currentTarget
      code = e.keyCode or e.which

      if code is 13
        if e.target.tagName isnt "TEXTAREA" and
            not e.target.className.match /select2/
          e.preventDefault()
          @getEl("submit").click()


      if nameAttribute = $el.attr('name')
        key   = @keySplitter(nameAttribute).join '.'
        value = _.get data, key
        # value = $el.val()

        # валидация в процессе редактирования формы, используя только клиент валидацию
        @preValidate key, value, $el

        @setRelation key, value
        # пересчитываем данные, на случай изменений значений
        data = @view.serialize()

    isChanged = @view.isChanged

    @view.isChanged = not _.isEqual @defaultData, data

    @view.trigger "form:change", data

    if @view.isChanged and isChanged isnt @view.isChanged

      unless @options.preventSubmitDisabling
        @getEl "submit"
        .prop "disabled", false

      @view.trigger "form:changed"

    if not @view.isChanged and isChanged isnt @view.isChanged

      unless @options.preventSubmitDisabling
        @getEl "submit"
        .prop "disabled", @defaultSubmitDisabled

      @view.trigger "form:reset"

  preValidate: (key, value, $el) ->
    return unless @options.isAutoValidate
    return unless @options.listen.preValidate

    error = @options.listen.preValidate key, value
    if error
      (_error = {})[key] = error
      @options.listen.trigger 'invalid', @options.listen, _error, inline: true
      $el.focus()
    else @reset $el

  setRelation: (key, value) ->
    return if not @relation or not @relation[key]

    if _.isFunction @relation[key]
      _rels = @relation[key] value
    else
      _rels = @relation[key]

    _rels = [ _rels ] unless _.isArray _rels

    _.each _.compact(_rels), (item) =>
      $_elem = @getElByName item.field
      type   = $_elem.attr('type')

      if not _.isUndefined(item.hide)
        $_elem.closest(@options.row)[if item.hide then 'hide' else 'show']()

      if not _.isUndefined(item.value)
        switch type
          when 'checkbox'
            if item.value
              $_elem.prop 'checked', true
            else
              $_elem.removeAttr 'checked'
          else
            $_elem.val item.value
            @preValidate item.field, item.value, $_elem

        @setRelation item.field, item.value if key and item.field isnt key

      if not _.isUndefined(item.disabled)
        $_elem.prop 'disabled', item.disabled
        @reset $_elem

  onDestroy: ->
    @getEl 'removeSelect2'
    .select2 'destroy'

  onError: ->

    listen = arguments[0]
    xhr    = arguments[1]

    # TODO: handle 500 error, add dict with known server errors
    # and resolve the way of errors visualization

    # TODO: handle 504 Gateway Timeout error
    # this code would be driven to show notification in
    # form (while it's open) or with pnotifier
    # err = if xhr.status is 504
    #     # if form is open
    #     # ...
    #     misc: [
    #         App.t "error.codes.504"
    #     ]
    #     # else
    #     #     App.Notifier.showError {}
    # else
    #     xhr.responseJSON

    err = xhr.responseJSON
    origin = _.cloneDeep err

    if origin?.model
      delete origin.model

    # there is no json body for 500 status
    if err

      if models = err?.model
        delete err.model

      for k of err
        for i of err[k]
          if listen.validation[k] and o = _.find listen.validation[k], err[k][i]
            if o.msg
              err[k][i] = o.msg if o.msg
            else if o.fn
              err[k][i] = o.fn.call listen, null, k, models
          else if fn = App.Common.ValidationModel::validators[err[k][i]]
            err[k][i] = fn.call listen, null, k, models
          else
            key = err[k][i]
            if _.isString key
              err[k][i] = listen.t key,
                item    : err.model
                context : 'error'
                name    : k

      err = listen.error err, models, origin if listen.error

      @invalid.call @, listen, err


    @$form
    .attr 'data-form-state', ''

    @getEl 'submit'
    .attr 'data-form-state', ''
    .prop 'disabled', false

  onSync: ->
    @reset()

    @defaultData = @view.serialize() if @options.syphon

    @view.isChanged = false

    @$form
    .attr 'data-form-state', ''

    # при сохранении меняем время сохранения
    # TODO: подумать, чтобы вынести даты как отдельный хелпер
    $changeDate = @getEl 'changeDate'
    if $changeDate.length
      $changeDate
      .text moment.utc(@options.listen.get('CHANGE_DATE')).local().format('L LT')

    unless @options.preventSubmitDisabling
      @getEl 'submit'
      .attr 'data-form-state', ''
      .prop 'disabled', @defaultSubmitDisabled

  onRequest: ->
    @$form
    .attr 'data-form-state', 'loading'

    @getEl 'submit'
    .attr 'data-form-state', 'loading'
    .prop 'disabled', true

  getEl: (el) ->
    el = @options[el] or el if _.isString(el)

    # Each item in array can be a option key, not just a selector
    if _.isArray(el)
      elements = $()
      _.each el, (selector) =>
        elements = elements.add @getEl selector
    else
      elements = formHelpers.getFormEl el, @el

    elements

  getElByName: (names) ->
    formHelpers.getFormElByName names, @$form, "form"

  keySplitter: (name) ->
    # DEPRECATED: после того, как впилить глобально keysplitter, выпилить
    # заменить на Backbone.Syphon.KeySplitter
    name.match(/[^\[\]]+/g)

  reset: ($el) ->
    if $el?.closest
      $el = $el.closest "[#{attr.error}]"
    else
      $el = @$form.find "[#{attr.error}]"

    $el.trigger 'blur.popover'
    .removeData 'content'
    .removeAttr attr.error

    # TODO: Реализовать единый сброс всех полей формы
    # учесть ситуации, когда форма не связана напрямую с вьюхой
    # для этого возможно придется рефакторить некоторые разделы
    # после выработки требований, совместно с дизайнером
    $ "[#{attr.errorMessage}=#{@view.cid}]"
    .remove()

  invalid: (model, err, _options) ->
    # inline: true - если валидация идет по одному полю
    @reset() if not _options or not _options.inline

    for k of err
      err[k] = [ err[k] ] unless _.isArray err[k]

      flatten = k.split('.')
      if flatten.length > 1
        el = ""

        for elem, index in flatten
          if index is 0
            el += "#{elem}"
          else
            el += "[#{elem}]"
      else
        el = k

      if k is 'misc'
        $el = @getEl 'submit'
      else
        $el = @getElByName [el, k]
        continue if $el.prop 'disabled'

      $container = $el.closest @options[ if k is 'misc' then 'footer' else 'elem' ]

      html = Marionette.Renderer.render "controls/form/error_message",
        key   : k
        error : err[k]
        cid   : @view.cid

      $container
      .attr attr.error, ""

      if k is 'misc'
        $container
        .append html
      else
        $container
        .attr 'data-popover-template', 'controls/popover_error'
        .data content: html
