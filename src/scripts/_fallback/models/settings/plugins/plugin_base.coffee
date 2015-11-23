"use strict"

Tokens = require 'models/settings/plugins/tokens.coffee'

module.exports = class PluginBase extends Backbone.Model

  is_event_licensed : (event_type, protocol) ->
    total = 0

    if @licenses?.length
      for license in @licenses
        is_find = _.find license.licenseMask, (mask) ->
          reg = new RegExp(mask, 'ig')
          reg.test "#{event_type}::#{protocol}"

        # Проставляем значение
        # 0 - не лицензированно
        # 1 - протухла лицензия
        # 2 - лицензирован
        if is_find
          if @is_license_active(license)
            t = 2

            # Если нашли уже самый лучший вариант
            # прекращаем цикл
            total = t
            break
          else
            t = 1
        else
          t = 0

        total = t if t > total

    total

  parse: ->
    response = super

    response.tokens = new Tokens(response.tokens)
    response.tokens.plugin_id = response.PLUGIN_ID

    # Собираем из них ключи вида <object_type_code_mnemo>::<protocol_mnemo>
    # из используемых плагином типов событий
    response.pluginUsesEventsToProtocols = _.map response.uses_events, (event) ->
      event_mnemo = event.MNEMO

      if event.protocols
        _.map event.protocols, (protocol) ->
          "#{event_mnemo}::#{protocol.MNEMO}"

    # Собираем из них ключи вида <object_type_code_mnemo>::<protocol_mnemo>
    # из добавленных плагином типов событий
    response.pluginAddsEventsToProtocols = _.map response.adds_events, (event) ->
      event_mnemo = event.MNEMO

      if event.protocols
        _.map event.protocols, (protocol) ->
          "#{event_mnemo}::#{protocol.MNEMO}"

    # Приводим массив к одномерному и убираем дубликаты
    response.pluginAddsEventsToProtocols = _.uniq _.flatten response.pluginAddsEventsToProtocols

    # Приводим массив к одномерному и убираем дубликаты
    response.pluginUsesEventsToProtocols = _.uniq _.flatten response.pluginUsesEventsToProtocols

    if response.licenses
      for license in response.licenses
        # Убираем фичи лицензии от технологий и не от нашего common_name
        features = _.reject license.features, (feature) ->
          _.keys(feature)[0].indexOf('cas') isnt -1 or
            not feature.object_type or
            feature.common_name isnt 'IW'

        eventsToProtocol = _.union(response.pluginAddsEventsToProtocols, response.pluginUsesEventsToProtocols).join(' ')

        # Отсеиваем только те фичи, которые есть в плагине
        features = _.filter features, (feature) ->
          object_type = if feature.object_type is '*' then '' else feature.object_type
          protocol = if feature.protocol is '*' then '' else feature.protocol

          eventsToProtocol.indexOf("#{object_type}::#{protocol}") isnt -1

        features = _.uniq features

        license.pluginFeatures = features

    if response.licenses
      for license in response.licenses
        license.licenseMask = _.uniq _.map license.pluginFeatures, (lic) ->
          object_type = if lic.object_type is '*' then '.*' else lic.object_type
          protocol    = if lic.protocol is '*' then '.*' else lic.protocol

          "#{object_type}::#{protocol}"

    response
