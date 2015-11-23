"use strict"

module.exports = App.Style =

  formatDate        : "DD-MM-YYYY 00:00:00"
  formatDateRangePicker : 'DD.MM.YYYY'
  formatTime        : "HH:mm DD-MM-YYYY"

  attr:
    error        : "data-error"
    errorMessage : "data-error-message"

  selector:
    filtered : '.filtered'

    select2:
      result    : ".select2__result"
      selection : ".select2__selection"

    toggle: '[data-action=toggle]'

    button:
      success : "._success"
      cancel  : ".button-cancel"

    popover:
      entry   : '[data-entry-id]'
      default : '[data-error]:not(:focus),[data-popover-el]'
      title   : '[title]:not(input)'
      slick   : '.slick-cell.invalid input,[data-error]'

    container: [
      '[data-el=container]'
      '#layout__sidebar>div'
      '#layout__content'
      '.popup__indent' # TODO: навести порядок в классах;
      '[data-region=form]'
      '#popup--content'
      'body'
    ]

  toolbar:
    visibleButton: ['create', 'add', 'edit', 'delete', 'show']

  className:
    active   : 'active'
    inactive : 'inactive'
    selected : 'selected'
    broken   : 'broken'
    default  : '_default'
    filtered : 'filtered'

    positionLeft  : '_left'
    positionRight : '_right'

    drag:
      dropReject: 'drop-reject'

    button:
      success : "_success"
      cancel  : "button-cancel"

    toolbar:
      create     : "_create"
      add        : "_create"
      info       : "fontello-icon-info"
      edit       : "_edit"
      "delete"   : "_delete"
      activate   : "fontello-icon-light-up"
      deactivate : "fontello-icon-off"
      import     : "fontello-icon-download"
      export     : "fontello-icon-upload"
      policy     : "fontello-icon-doc-text"
      addSystem  : "fontello-icon-arrow-curved"
      down       : "fontello-icon-down-dir"
      up         : "fontello-icon-up-dir"

    statusFile:
      "1"  : "fontello-icon-upload"
      "2"  : "fontello-icon-arrows-cw"
      "3"  : "fontello-icon-arrows-cw"
      "4"  : "fontello-icon-arrows-cw"
      "5"  : "fontello-icon-ok-3"
      "-1" : "fontello-icon-cancel-5"

    action:
      apply             : "[ icon _sizeSmall _actionApply ]"
      NOTIFY            : "[ icon _sizeSmall _noticeOfficer ]"
      NOTIFY_SENDER     : "[ icon _sizeSmall _noticeUser ]"
      VIOLATION         : "[ icon _threat ]"
      TAG               : "[ icon _sizeSmall _actionTag ]"
      ADD_PERSON_STATUS : "[ icon _sizeSmall _status ]"
      BLOCK             : "[ icon _sizeSmall _actionBlock ]"
      QUARANTINE        : "[ icon _sizeSmall _actionQuarantine ]"
      DELETE            : "[ icon _sizeSmall _actionDelete ]"

    entry:
      person            : "[ icon _sizeSmall _sid ]"
      user              : "[ icon _sizeSmall _sid ]"
      group             : "[ icon _sizeSmall _accessPublic ]"
      workstation       : "[ icon _sizeSmall _computer ]"
      status            : "[ icon _sizeSmall _status ]"
      share             : "fontello-icon-cc-share"
      sharepoint        : "fontello-icon-database"
      local             : "fontello-icon-cc-share"
      resource          : "fontello-icon-cc-share"
      email             : "[ icon _sizeSmall _email ]"
      phone             : "[ icon _sizeSmall _phone ]"
      mobile            : "[ icon _sizeSmall _mobile ]"
      skype             : "[ icon _sizeSmall _skype ]"
      lotus             : "[ icon _sizeSmall _lotus ]"
      icq               : "[ icon _sizeSmall _icq ]"
      printers          : "[ icon _sizeSmall _printer ]"
      webaccount        : "[ icon _sizeSmall _webaccount ]"
      removable         : "fontello-icon-inbox"
      perimeter         : "[ icon _sizeSmall _perimeter ]"
      url               : "[ icon _sizeSmall _domain ]"
      url_with_masks    : "[ icon _sizeSmall _domain ]"
      domain            : "[ icon _sizeSmall _emailDomain ]"
      ip                : "fontello-icon-net"
      dns               : "fontello-icon-net"
      fingerprint       : ""
      text_object       : ""
      stamp             : ""
      form              : ""
      table             : ""
      category          : ""
      graphic           : ""

    channel:
      im_skype          : "[ icon _sizeSmall _skype ]"
      im_icq            : "[ icon _sizeSmall _domain ]"
      im_mail_ru        : "fontello-icon-at"
      email_smtp        : "[ icon _sizeSmall _email ]"
      email_receive     : "[ icon _sizeSmall _email ]"
      email_web         : "[ icon _sizeSmall _email ]"
      web_common        : "[ icon _sizeSmall _domain ]"
      im_other          : "fontello-icon-jabber"
      file_copy_out     : "fontello-icon-upload"
      print_common      : "[ icon _sizeSmall _print ]"
      file_exchange     : "fontello-icon-ftp"
      phone_sms         : "[ icon _sizeSmall _phone ]"
      multimedia_photo  : "fontello-icon-picture-1"
