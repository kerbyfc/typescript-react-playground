"use strict"

module.exports = class SystemCheckServerDialog extends Marionette.ItemView

  # ****************
  #  MARIONETTE
  # ****************

  template: "settings/dialogs/system_check_server"

  ui:
    save                  : "[data-action='save']"
    check                 : "[data-action='check']"
    recipients            : "[name='mailing_list[]']"
    enable_notifications  : "#enable_notifications"
    server                : '[name="smtp_server__smtp"]'
    port                  : '[name="smtp_server__port"]'
    prefix                : '[name="prefix"]'

  events:
    "click @ui.save"    : "save"
    "click @ui.check"   : "check"

  templateHelpers: ->
    title           : @options.title

  behaviors: ->
    data = @options.model.toJSON()

    data.enable_notifications = +data.enable_notifications

    Form:
      listen : @options.model
      syphon : data

  # *************
  #  PRIVATE
  # *************

  _get_$select2_text_input = ($ui_recipients) ->
    $ui_recipients.data "select2"
    .container.find ".select2-input"

  _init_email_selected = ($el, cb) ->
    cb $el.val().split(",")

  _parse_email_search = (response, page, options) ->
    results :
      []
      .concat(
        _.filter response.data.user, (user_data) ->
          !!user_data.EMAIL
      )
      .concat(
        _ response.data.person
        .map (person_data) ->
          _ person_data.contacts
          .filter (contact_data) ->
            contact_data.CONTACT_TYPE is "email"
          .map (contact_data) ->
            DISPLAY_NAME : person_data.DISPLAY_NAME
            PERSON_ID  : person_data.PERSON_ID
            VALUE    : contact_data.VALUE
          .value()
        .flatten true
        .value()
      )
      .concat(
        if options.term.match App.Helpers.patterns.email
          options.term
        else
          []
      )

  _receive_email = (item) ->
    if _.isString item
      item
    else if item.USER_ID
      item.EMAIL
    else if item.PERSON_ID
      item.VALUE

  _view_email_search = (result_item) ->
    (
      if _.isString result_item
        "
          <i class=fontello-icon-mail-2></i>
          #{ result_item }
            "
      else if result_item.USER_ID
        "
          <i class=fontello-icon-user></i>
          #{ App.t "global.console_user" }:
              #{ result_item.DISPLAY_NAME } (#{ result_item.EMAIL })
            "
      else if result_item.PERSON_ID
        "
          <i class=fontello-icon-user></i>
          #{ App.t "organization.person" }:
              #{ result_item.DISPLAY_NAME } (#{ result_item.VALUE })
            "
    )
    .replace /.*/, (str) ->
      "<div title='#{str}'>#{ str }</div>"

  _view_email_selected = (item) ->
    (
      if _.isString item
        item
      else if item.USER_ID
        item.EMAIL
      else if item.PERSON_ID
        item.VALUE
    )
    .replace /.*/, (str) ->
      "<div title='#{str}'><i class=fontello-icon-mail-2>#{ str }</div>"

  # ***********************
  #  MARIONETTE-EVENTS
  # ***********************

  check: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).attr('disabled') then return

    @model.send_test_messages().then(
      ->
        App.Notifier.showSuccess text : App.t "settings.crash_notice.test_success"
      (error) ->
        App.Notifier.showError
          text : "
            #{ App.t "settings.crash_notice.test_error" }:
            #{ error }
          "
    )

  save: (e) ->
    e?.preventDefault()

    if $(e.currentTarget).prop('disabled') then return

    data = @getData()

    data.mailing_list = data.mailing_list.split(',')

    @options.callback(data)

  onDestroy: ->
    App.Common.ValidationModel::unbind @

    @ui.recipients.select2 "destroy"

  setEditState: (state) ->
    @ui.server.prop "disabled", state
    @ui.port.prop "disabled", state
    @ui.prefix.prop "disabled", state
    @ui.recipients.select2('enable', not state)

  onShow: ->
    @ui.enable_notifications.on 'change', (e) =>
      if $(e.currentTarget).prop('checked')
        @setEditState(false)
      else
        @setEditState(true)

    @ui.recipients.select2
      ajax :
        data                : (term) -> query : term
        results             : _parse_email_search
        url                 : "#{ App.Config.server }/api/search?scopes=person,user"
      formatResult          : _view_email_search
      formatSelection       : _view_email_selected
      id                    : _receive_email
      initSelection         : _init_email_selected
      minimumInputLength    : 3
      multiple              : true

    App.Common.ValidationModel::bind @

    unless @model.get('enable_notifications')
      @setEditState(true)

