"use strict"

class animatedRegion extends Marionette.Region

  attachHtml: (view) ->
    if view.options.isAnimated
      @$el.empty().append(view.el)
      @$el.hide().toggle('slide', {direction: view.options.direction or 'right'}, 400)
    else
      super

class SessionParams extends Marionette.ItemView

  template: 'crawler/tasks/task_session_params'

  templateHelpers:
    scanningMode: ->
      switch @ScanMode
        when 'AllFolders'
          result = App.t 'crawler.job_details_common_mode_AllFolders'
        when 'AllExceptForbidden'
          result = """
            #{App.t 'crawler.job_details_common_mode_expect'}
            <br/>
            #{@Filters.ForbiddenPathFilter.path.replace(/;/g, "<br/>")}
          """
        when 'OnlyAllowed'
          result = """
            #{App.t 'crawler.job_details_common_mode_allowed'}
            <br/>
            #{@Filters.AllowedPathFilter.path.replace(/;/g, "<br/>")}
          """

      if @FileSystem.excludeSystemFolders is "true"
        result += "<br/><br/>(#{App.t 'crawler.job_details_common_mode_exclude_system'})"

      result

    scanProfile: ->
      switch @scanPolicy
        when 'FilesShare'
          if @FileSystem.scanAdminShares is "true"
            App.t 'crawler.job_details_common_scan_policy_local'
          else
            App.t 'crawler.job_details_common_scan_policy_network'
        when 'DBFileStorage'
          version = switch @FileSystem.scriptId
            when '1'
              "SharePoint 2007"
            when '2'
              "SharePoint 2010"
            when '3'
              "SharePoint 2013"

          App.t 'crawler.job_details_common_scan_policy_sharepoint',
            version: version

class SessionEvents extends App.Views.Controls.Grid

  template: "crawler/tasks/task_session_events"

  resizeElement: '.content__indent'

class Sessions extends App.Views.Controls.Grid

  template: "crawler/tasks/task_sessions"

  resizeElement: '.content__indent'

class AdvancedSessionInfo extends Marionette.LayoutView

  template: "crawler/tasks/advanced_session_info"

  regions:
    history : "[data-region='history']"
    params  : "[data-region='params']"

  triggers:
    'click [data-action="back"]': 'back'

  onShow: ->
    @history.show new SessionEvents
      collection: @model.get 'Events'

    @params.show new SessionParams
      model: @model.get 'Params'

module.exports = class TaskInfo extends Marionette.LayoutView

  template: "crawler/tasks/task_info"

  className: "content"

  regions:
    sessions:
      regionClass: animatedRegion
      selector: "[data-region='sessions']"

  ui:
    downloadReport : "[data-action='download_report']"

  events:
    back                        : "back"
    "click @ui.downloadReport"  : 'downloadReport'

  _blockToolbar: ->
    @ui.downloadReport.prop "disabled", true

  _updateToolbar: (selected) ->
    @_blockToolbar()

    if selected and selected.length is 1 and selected[0].get('status') isnt "0"
      @ui.downloadReport.prop "disabled", false

  downloadReport: ->
    selected = @sessions.currentView.collection.getSelectedModels()

    if selected and selected.length
      for session in selected
        window.location = "#{App.Config.server}/api/crawler/report/#{ session.get('guid')}"

  back: ({collection, model, view}) ->
    @_showSessions @model, true, 'left'

  _showAdvancedSessionInfo: (model, isAnimated = false) ->
    @sessions.show new AdvancedSessionInfo
      model: model
      isAnimated: isAnimated

    Marionette.bindEntityEvents @, @sessions.currentView, @events

  _showSessions: (model, isAnimated = false, direction = 'right') ->
    @sessions.show new Sessions
      model       : model
      collection  : model.sessions
      isAnimated  : isAnimated
      direction   : direction

    Marionette.bindEntityEvents @, @sessions.currentView, @events

    @listenTo @sessions.currentView, "table:select", @_updateToolbar

    @listenTo @sessions.currentView, "table:click", (model, e, options) =>
      if options.cell isnt 0
        @_showAdvancedSessionInfo(model, true)

  onShow: ->
    @_showSessions(@model)

    @_updateToolbar()
