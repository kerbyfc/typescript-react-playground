"use strict"

window.$ = require "jquery"
window.jQuery = window.$
window._ = require "lodash"
window.Backbone = require "backbone"
window.Marionette = require "backbone.marionette"
window.moment = require "moment"
require "moment-range"

require "app.coffee"
require "common/backbone.coffee"
require "common/backbone-paginator.coffee"
require "common/backbone-syphon.coffee"
require "common/backbone-validation.coffee"
require "common/backbone-nested.coffee"
require "common/marionette.coffee"
require "common/helpers.coffee"
require "common/pnotify.coffee"
require "session.coffee"
require "controllers/licenses_manager.coffee"
require "bootstrap"
require "views/controls/entry.coffee"

if window.__karma__?
  $ "body"
  .append "<div class=layout>"

App.start()
