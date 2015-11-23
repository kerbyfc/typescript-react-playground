"use strict"

require "bootstrap"
require "views/controls/table_view.coffee"

App.module "Configuration.Dialogs",
  startWithParent: true
  define: (Configuration, App, Backbone, Marionette, $) ->

    App.Views.Configuration ?= {}

    class App.Views.Configuration.ConfigurationEmpty extends Marionette.ItemView

      template: "configuration/configuration_empty"

      className: 'configuration__loading'

    class App.Views.Configuration.ConfigurationLogItem extends Marionette.ItemView

      template: "configuration/configuration_item"

      className: 'configuration__item'

      initialize: ->
        @mutators =
          COLOR: (color) ->
            "<div class='tag__color' data-color='#{color}'></div>"

          ENABLED: (value) =>
            if parseInt(value, 10)
              @locale.active
            else
              @locale.unactive

          STATUS: (value) =>
            if parseInt(value, 10)
              @locale.active
            else
              @locale.inactive

          IS_REGEXP: (value) =>
            if parseInt(value, 10)
              @locale.type_regexp
            else
              @locale.type_string

          CHARACTERISTIC      : @_translateBoolean
          TERM_CASE_SENSITIVE : @_translateBoolean
          CASE_SENSITIVE      : @_translateBoolean
          TERM_MORPHOLOGY     : @_translateBoolean
          IS_EMPLOYEE         : @_translateBoolean
          MORPHOLOGY          : @_translateBoolean

        options = returnObjectTrees: true

        @locale = App.t 'global', options

        switch @model.get 'ENTITY'
          when 'Tag'
            key = 'lists.tags'
          when 'LdapStatus'
            key = 'lists.statuses'
          when 'systemlist'
            key = 'lists.resources'
          when 'Term'
            key = 'analysis.term'

            languages = App.t 'language', options
            @locale = _.merge @locale, languages
          when 'Category'
            key = 'analysis.category'

            fields = @model.get('FIELDS')
            entity = fields?[@model.get('ENTITY')] or fields?.new[@model.get('ENTITY')]
            type = entity.TYPE

            keyLocale = if type is 'term' then "category" else "group_#{type}"
            title = App.t "select_dialog.#{keyLocale}", context: 'title'
            title = title.toLowerCase()

            languages = App.t 'language', options
            @locale = _.merge @locale, languages
          when 'Perimeter'
            key = 'lists.perimeters'
          when 'ProtectedCatalog'
            key = 'protected.catalog'
          when 'ProtectedDocument'
            key = 'protected.document'
          when 'LdapGroup'
            key = 'organization'
          when "LdapWorkstation", "LdapPerson"
            key = "organization"
            conditions = App.t "events.conditions", options
            @locale = _.merge @locale, conditions
          when 'SystemList'
            key = 'lists.resources'
          when 'Fingerprint'
            key = 'analysis.fingerprint'
          when 'TextObject'
            textObjectLocale = App.t 'analysis.text_object', options
            textObjectPatternLocale = App.t 'analysis.text_object_pattern', options
            country = App.t 'country', options

            @locale = _.merge @locale,
              textObjectLocale,
              textObjectPatternLocale,
              country
          when 'EtForm'
            key = 'analysis.form'
          when 'EtStamp'
            key = 'analysis.stamp'
          when 'EtTable'
            key = 'analysis.table'
          when 'Policy'
            key = 'entry.policy'

        @locale.title = title
        _.extend @locale, App.t(key, options) if key

      serializeData: ->
        _.extend super,
          locale   : @locale
          mutators : @mutators

      ##########################################################################
      # PRIVATE

      ###*
       * Exchanges 0 and 1 to translated values
       * @param {String|Number} data - incoming 0 or 1 data
       * @result {String} resulting string in current locale
      ###
      _translateBoolean: (data) ->
        if parseInt(data, 10)
          App.t 'global.yes'
        else
          App.t 'global.no'


    class App.Views.Configuration.ConfigurationLogDialog extends Marionette.CompositeView

      template: "configuration/configuration"

      childView: App.Views.Configuration.ConfigurationLogItem

      childViewContainer: '.configuration'

      emptyView: App.Views.Configuration.ConfigurationEmpty

      events: 'click [data-action=save]': 'save'

      save: (e) ->
        e.preventDefault()

        # Собираем данные с контролов
        data = Backbone.Syphon.serialize(@)

        @options.callback(data, @)

      onDestroy: ->
        App.Common.ValidationModel::.unbind(@)

      onShow: ->
        App.Common.ValidationModel::.bind(@)

        @collection.fetch wait: true

      serializeData: -> _.extend super, action: @options.action
