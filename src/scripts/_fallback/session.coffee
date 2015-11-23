"use strict"

require "app.coffee"
require "routes/application.coffee"
require "controllers/login.coffee"
Users = require "models/settings/user.coffee"
require "models/settings/licenses.coffee"
tabEventBus = require "common/tab_event_bus.coffee"
TimeIdler = require "common/time_idler.coffee"
bookworm = require "controllers/bookworm.coffee"

Licenses = require "models/settings/licenses.coffee"

ReportsController = require "controllers/reports.coffee"

App.module "Session",
  startWithParent: false
  define: (Session, App, Backbone, Marionette, $) ->
    class SessionController extends Marionette.Controller

      # Возвращает текущего пользователя
      currentUser: -> @user

      _showQuerySuccess: (message) ->
        App.Notifier.showSuccess
          title: App.t 'events.conditions.selection'
          text: App.t 'events.conditions.selection_done',
            name: message.data.data.DISPLAY_NAME
            id: message.data.data.QUERY_ID
          hide: if message.data.show is 'sticky' then false else true

      _showQueryError: (message) ->
        if message.data.data.error
          error = message.data.data.error
        else
          if message.data.message
            if $.i18n.exists "events.events.#{message.data.message}"
              error = App.t "events.events.#{message.data.message}"
            else
              error = message.data.message

        App.Notifier.showError
          title: App.t 'events.conditions.selection'
          text: App.t 'events.conditions.selection_error',
            name: message.data.data.DISPLAY_NAME
            error: error
          hide: if message.data.show is 'sticky' then false else true

      # Обрабатывает сообщения пользователя
      receiveUserMessage: (message) =>
        d = message.data.data

        switch message.data.module
          when 'sample_compiler'
            App.vent.trigger "analysis:create", message.data.type, message.data.data

          when 'object_reporter'
            switch message.data.type
              when 'success'
                locale = App.t('events', { returnObjectTrees: true })

                query_name  = locale.conditions[d.query] or d.query
                filename    = _.escape d.filename
                path        = _.escape d.path
                App.Notifier.showSuccess
                  title: App.t 'events.events.export'
                  text: "#{ App.t 'events.events.export_done', {selection: query_name} }
                       [<a href='#{App.Config.server}/api/object/ReportFile?queryId=#{d.queryId}&filename=#{filename}&path=#{path}'
                       target='_blank'>#{App.t 'global.download'}</a>]",
                  hide: false
              when 'error'
                locale = App.t('events', { returnObjectTrees: true })
                query_name = locale.conditions[d.query] or d.query

                switch message.data.error
                  when 'Error file open'
                    error = "#{ App.t 'events.events.error_on_file_open', {selection: query_name} }"
                  when 'File type is not supported'
                    error = "#{ App.t 'events.events.error_file_type', {selection: query_name} }"
                  else
                    error = "#{ App.t 'events.events.export_fail', {selection: query_name} }"

                App.Notifier.showError
                  title: App.t 'events.events.export'
                  text: error
                  hide: false

          when 'query_reporter', 'query_reporter_generate'
            data = message.data.data
            data.type = message.data.type
            ReportsController.cometHandler.handle message.data.module, data

          when 'reporter'
            switch message.data.type
              when 'success'
                App.Notifier.showSuccess
                  title: App.t 'dashboards.dashboards.report'
                  text: "#{ App.t 'dashboards.dashboards.report_done', {name: message.data.data.DISPLAY_NAME} }
                       [<a href='#{App.Config.server}/public/#{message.data.data.HASH}.pdf' target='_blank'>pdf</a>]
                       [<a href='#{App.Config.server}/public/#{message.data.data.HASH}.html' target='_blank'>html</a>]",
                  hide: if message.data.show is 'sticky' then false else true

          when 'diagnostic_report'
            data = message.data.data
            if (file = data.file)
              data.fileName = file.match(/([^\s^\/]+(?=\.(\w+)))/)[1]
              App.Notifier.showSuccess
                text: App.t('events.diagnostic.success__text', data)

          when 'selection'
            # Если закончил работу запрос из Events
            if (message.data.data.QUERY_ID of App.EventsConditionsManager.Events)
              # если модуль Events запущен
              if App.Controllers.Events
                if message.data.type is 'error'
                  if parseInt(App.Controllers.Events.selectedQuery, 10) is parseInt(message.data.data.QUERY_ID, 10)
                    App.Controllers.Events.trigger 'selection:failed', message
                  else
                    @_showQueryError(message)
                else
                  if parseInt(App.Controllers.Events.selectedQuery, 10) is parseInt(message.data.data.QUERY_ID, 10)
                    App.Controllers.Events.trigger 'selection:done', message.data.data.QUERY_ID
                  else
                    @_showQuerySuccess(message)
              else
                if message.data.type is 'error'
                  @_showQueryError(message)
                else
                  @_showQuerySuccess(message)

              delete App.EventsConditionsManager.Events[message.data.data.QUERY_ID]

      start: (userSession) ->
        # Проверяем браузер
        if App.Helpers.checkBrowser()

          @user = new Users.Model userSession or {}
          @listenTo @user, 'user:destroy', @destroy
          @listenTo @user, 'user:create', @create

          if not userSession
            @user.destroySession()
          else
            @user.createSession(userSession)
        else
          @destroy()

      stop: ->
        App.module("Application").stop()
        @user.destroySession()

      create: ->
        bookworm.fetch()
        .then =>

          App.module("Login").stop()
          App.module("Application").start()

          switch @currentUser().get('LANGUAGE')
            when 'rus'
              moment.lang('ru')
            when 'eng'
              moment.lang('en')

          App.vent.once "auth:logout", @user.logout, @user

          @user.on 'message', @receiveUserMessage

          @initIdler()

          @_checkLicenses()

        .catch (err) ->
          App.Notifier.showError
            text: App.t 'notify.service_unavailable'
          throw err

      destroy: ->
        # Закрываем все popover
        $('.popover-link a').each ->
          if not $(@).is(e.target) and $(@).has(e.target).length is 0 and $('.popover').has(e.target).length is 0
            $(@).popover('hide')

        App.currentModule.stop() if App.currentModule
        App.currentModule = null

        if App.Routes.Application
          App.Routes.Application.navigate "/"

        bookworm.stop()
        App.module("Application").stop()
        App.module("Login").start()

        @user.off 'message'

        localStorage.setItem('last_license_notification', 0)

        @deinitIdler()

        PNotify.removeAll()

      # Проверка лицензий
      _checkLicenses: ->
        return if localStorage.getItem('last_license_notification') is '1'
        localStorage.setItem('last_license_notification', 1)

        currentLicense = App.LicenseManager.getCurrentLicense()
        nextLicense = App.LicenseManager.getNextLicense()

        # Есть ли лицензия
        if currentLicense
          unlicensedPeriod = App.LicenseManager.computeUnlicensedPeriod(currentLicense, nextLicense)
          hasUnlicensedPeriod = unlicensedPeriod?.diff('days') > 0

          # Подходит ли лицензия к концу
          if currentLicense.isAboutEnds()

            # Если есть нет резервной лицензии
            if not nextLicense
              App.Notifier.showWarning
                text: App.t 'settings.license.license_expiration',
                  begin: currentLicense.getEndDate().format('DD-MM-YYYY')

            # Если есть резервная лицензия и есть нелицензионный период
            else if hasUnlicensedPeriod
              App.Notifier.showWarning
                text: App.t 'settings.license.license_expiration_with_reserve',
                  begin: unlicensedPeriod.start.format('DD-MM-YYYY')
                  end: unlicensedPeriod.end.subtract(1, 'days').format('DD-MM-YYYY')
                  nextBegin: nextLicense.getBeginDate().format('DD-MM-YYYY')

        # Сейчас нелицензионный период
        else
          prevLicense = App.LicenseManager.getPrevLicense()
          unlicensedPeriod = App.LicenseManager.computeUnlicensedPeriod(prevLicense, nextLicense)

          # Если есть закончившаяся лицензия
          if prevLicense

            # Если есть резервная лицензия
            if nextLicense
              App.Notifier.showError
                text: App.t 'settings.license.unlicensed_period_with_reserve',
                  begin: unlicensedPeriod.start.format('DD-MM-YYYY')
                  end: unlicensedPeriod.end.subtract(1, 'days').format('DD-MM-YYYY')
                  nextBegin: nextLicense.getBeginDate().format('DD-MM-YYYY')

            # Если нет резервной лицензия
            else
              App.Notifier.showError
                text: App.t 'settings.license.license_expired',
                  prevEnd: prevLicense.getEndDate().format('DD-MM-YYYY')

          # Если не было лицензии ранее
          else

            # Если есть резервная лицензия
            if nextLicense
              App.Notifier.showError
                text: App.t 'settings.license.no_license_message_with_reserve',
                  nextBegin: nextLicense.getBeginDate().format('DD-MM-YYYY')

            # Если нет резервной лицензии
            else
              App.Notifier.showError
                text: App.t 'settings.license.no_license_message'

      # === PRIVATE ===

      initIdler: ->
        # Делаем сообщение между вкладками с помощью tabex
        tabEventBus.on 'time_idler.user_event', (number) =>
          @_timeIdler.reset()

        # Задаем таймаут сессии
        @_timeIdler = new TimeIdler
          timeout: 30 * 60 * 1000 # 30 минут

        @_timeIdler.on 'user_event', ->
          tabEventBus.send 'time_idler.user_event'

        @_timeIdler.on 'idle', =>
          @user.logout()

          App.Notifier.showSuccess
            title: App.t 'global.session'
            text: App.t 'global.session_expired_message'
            hide: false

        @_timeIdler.start()

      deinitIdler: ->
        if @_timeIdler

          tabEventBus.off 'time_idler.user_event'
          @_timeIdler.stop()

    # Initializers And Finalizers
    # ---------------------------
    Session.addInitializer (userSession) ->
      App.Session = new SessionController()
      App.Session.start(userSession)

    Session.addFinalizer ->
      App.Session.stop()
      delete App.Session


App.vent.on "session:start", (userSession) ->
  App.Session.start(userSession)
