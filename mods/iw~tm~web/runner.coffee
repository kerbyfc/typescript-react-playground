vertx     = require 'vertx'
container = require 'vertx/container'
moment    = require 'moment'
winston   = require 'winston'

eb     = vertx.eventBus
fs     = vertx.fileSystem
config = container.config

# build logs path for logger
# by its name
#
# @param name [ String ] logger name
# @return     [ String ] logger filepath
#
logPath = (name) ->
  # build path
  dir = config.logger?.common?.file?.path?.replace(/\/$/, '') or
    "../../logs/#{name}"

  # create directory
  unless fs.existsSync dir
    fs.mkDirSync dir, true

  dir + "/#{moment().format('llll').replace /\W/g, '_'}.log"

# configure common logger
winston.loggers.add 'common',
  console:
    level: 'silly'
    colorize: 'true'
    label: 'tm:common'
  file:
    filename: logPath 'common'
    maxsize: 500000
    maxFiles: 50

log = winston.loggers.get 'common'
log.emitErrs = true

eb.registerHandler 'log', (message, type = 'info', meta = {}) ->
  log[type]? message

# deploy module
#
# @param module [String] module name
# @param config [Object] module configuration
#
deploy = (module, config, instances) ->
  container.deployModule module, config, instances, (err, id) ->
    unless err
      log.info  "#{module} deployed: #{id}"
    else
      log.error "#{module} deployment failed: " + err.getMessage()

deploy "iw~tm.back~7.0", config.back
deploy "iw~tm.front~7.0", config.front
