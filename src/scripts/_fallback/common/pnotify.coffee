"use strict"

require "pnotify"
require "pnotify.buttons"
require "pnotify.nonblock"
require "pnotify.callbacks"
require "pnotify.confirm"
require "pnotify.desktop"
require "pnotify.history"
require "pnotify.reference"

defaults =
  hide  : false
  delay : 3000

  animate_speed : "fast"

notify = (preset, options) ->
  sticky = options.hide is false
  note   = new PNotify _.defaults options, defaults, preset

  if not sticky
    # HACK: use {hide:false} option to make note sticky,
    # to fix it's closing by click on "X"
    setInterval ->
      if not note.elem.is(":hover")
        note.remove()
    , options.delay

  # remove note by click on inner link
  note.elem.on "click", (e) ->
    if e.target.tagName is "A"
      note.remove()

  note

App.Notifier =

  showError: _.partial notify,
    type    : 'error'
    icon    : 'fontello-icon-cancel-circle-4'
    history : maxonscreen: 5

  showWarning: _.partial notify,
    type    : 'info'
    icon    : 'fontello-icon-attention-3'
    history : maxonscreen: 5

  showInfo: _.partial notify,
    type    : 'info'
    icon    : 'fontello-icon-attention-3'
    history : maxonscreen: 5

  showSuccess: _.partial notify,
    type    : 'success'
    icon    : 'fontello-icon-ok'
    history : maxonscreen: 5

PNotify.prototype.options.buttons.sticker = false
