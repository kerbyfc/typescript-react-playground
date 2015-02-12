requireDir = require "require-dir"
plumber    = require "gulp-plumber"
notify     = require "gulp-notify"

# Most often used requirements
requirements =
  gulp : require "gulp"

  # uppercase for convenience
  _    : require "lodash"
  GLOB : require "glob"
  PATH : require "path"
  FS   : require "fs-extra"
  YAML : require "yamljs"

# Make them global
requirements._.extend global, requirements,
  helpers: require "./helpers"

# load config
global.cfg = YAML.load "./gulp/config.yml"

# build paths
p = {}
for scope, paths of cfg.paths
  # save original
  p[scope] = _.clone paths

  # only for objects with base prop
  if _.isObject(paths) and _.has(paths, 'base')
    for key, _path of p[scope]
      # dont process base prop
      unless key is 'base'
        # it it's an object, process each item
        p[scope][key] = if _.isObject _path
          _.reduce _path, (m, v, k) ->
            m[k] = PATH.join p[scope].base, v; m
          , {}
        else
          # join relative and base paths
          PATH.resolve p[scope].base, _path

_.extend global,

  p: p

  src: ->
    source = gulp.src arguments...
    # prevent exit on error
    source.pipe plumber
      errorHandler: notify.onError "Error: <%= error.message %>
        \n <%= error.stack %>"

  save: ->
    if arguments.length
      gulp.dest arguments...
    else
      gulp.dest p.build.base

# Recursively require tasks
requireDir "./tasks", recurse: true

# build all assets
gulp.task "build", [
  "fonts:copy"
  "images:copy"

  "yaml:build"
  "scss:build"
  "jade:build"
  "codo:build"

  "scripts:build"
]

# rebuild
gulp.task "rebuild", ["cleanup"], ->
  gulp.start "build"

# build and watch all assets
gulp.task "default", [
  "fonts:copy"
  "images:copy"

  "yaml:serve"
  "scss:serve"
  "jade:serve"
  "codo:serve"

  "scripts:serve"

  "server:run"
  ]
