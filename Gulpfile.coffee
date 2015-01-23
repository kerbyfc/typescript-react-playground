path        = require "path"
gulp        = require "gulp"
karma       = require "karma"
YAML        = require "yamljs"
browserify  = require "gulp-browserify"
yaml        = require "gulp-yaml"
replace     = require "gulp-replace"
shell       = require "gulp-shell"
cjsx2coffee = require "gulp-coffee-react-transform"
plumber     = require "gulp-plumber"
cjsx        = require "gulp-cjsx"
notify      = require "gulp-notify"
webserver   = require "gulp-webserver"
clean       = require "gulp-clean"
tap         = require "gulp-tap"
sass        = require "gulp-sass"
cssimport   = require "gulp-cssimport"
_           = require "lodash"

################################################################################
# ENVIRONMENT

cfg = YAML.load "config.yml"

fullpath = (_path) ->
  path.resolve process.cwd(), _path

################################################################################
# STYLES

# compile sass
gulp.task "sass", ->
    gulp.src cfg.paths.scss_bootstrap
      .pipe sass
          includePaths: cfg.sass.includePaths
      .pipe replace /\((.*)(\.css)\)/g, '(/../bower_components/$1$2)'
      .pipe cssimport()
      .pipe gulp.dest cfg.paths.build

################################################################################
# TEMPLATES

# copy html from src to build
gulp.task "html", ->
  gulp.src cfg.paths.html
    .pipe plumber()
    .pipe gulp.dest cfg.paths.build


################################################################################
# SCRIPTS

# compile coffee jsx
gulp.task "cjsx", ->
  gulp.src cfg.paths.coffee
    .pipe plumber()
    .pipe cjsx bare: true
    .pipe gulp.dest cfg.paths.build

# ↓ #

# build application bundle with browserify
gulp.task "bundle", ["cjsx"], ->
  gulp.src cfg.paths.bootstrap
    .pipe plumber()
    .pipe browserify cfg.browserify
    .pipe gulp.dest cfg.paths.build

################################################################################
#  DOCUMENTATION

# cleanup doc directory
gulp.task "cleandoc", ->
  gulp.src cfg.paths.doc
    .pipe clean
      read: false

# ↓ #

# translate cjsx to coffee
gulp.task "cjsx2coffee", ["cleandoc"], ->
  gulp.src cfg.paths.coffee
    .pipe plumber()
    .pipe cjsx2coffee()
    .pipe gulp.dest cfg.paths.docsource

# ↓ #

# generate documentation for coffee
gulp.task "codo", ["cjsx2coffee"], shell.task [
  "./node_modules/.bin/codo --undocumented --closure #{cfg.paths.docsource} > #{cfg.paths.nodoc}"
]

################################################################################
# AUTOTESTS

gulp.task "karma", (done) ->
  karma.server.start
      configFile: fullpath cfg.paths.karma
    , done

################################################################################
# MISC

# if file stream has `shared":` substring
# try to parse json and pick only shared objects
pickShared = (stream) ->
  c = stream.contents.toString()
  if c.match /shared"[\s]*\:/
    try
      c = JSON.parse c
      # pick only
      stream.contents = new Buffer(
        JSON.stringify(
          _.pick(c, c.shared)
          null, 2
        )
      )
  stream

# transform .yml files
# to .json fils
gulp.task "yaml", ->
  gulp.src cfg.paths.yaml
    .pipe plumber()
    .pipe yaml
      space: 2
    .pipe tap pickShared
    .pipe gulp.dest cfg.paths.build

# start server to serve static
gulp.task "webserver", ->
  gulp.src cfg.paths.build
    .pipe plumber()
    .pipe webserver
      fallback: cfg.paths.index_file

gulp.task "cleanup", ->
  gulp.src cfg.paths.build
    .pipe clean
      read: false

################################################################################
#  MULTITASKS

# watch changes
gulp.task "watch", ->
  gulp.watch [
    cfg.paths.coffee
    cfg.paths.html
    cfg.paths.yaml
    "!node_modules"
    "!bower_components"
  ], ["rebuild"]

gulp.task "rebuild", ["cleanup"], ->
  gulp.start "build"

# build all assets
gulp.task "build", [
  "yaml"
  "bundle"
  "html"
  "sass"
  "codo"
]

# run server (to serve static) and watch changes
gulp.task "serve", ["rebuild"], ->
  gulp.start "webserver"
  gulp.start "watch"
  gulp.start "karma"

gulp.task "default", [
  "serve"
]
