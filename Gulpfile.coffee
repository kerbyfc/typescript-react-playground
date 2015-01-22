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

################################################################################
# ENVIRONMENT

cfg = YAML.load "config.yml"

fullpath = (_path) ->
  path.resolve process.cwd(), _path

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
gulp.task "cleanupdocsources", shell.task [
    "rm -rf #{cfg.paths.docs}"
  ]

# ↓ #

# translate cjsx to coffee (for documentation only)
gulp.task "cjsx2coffee", ["cleanupdocsources"], ->
  gulp.src cfg.paths.coffee
    .pipe plumber()
    .pipe cjsx2coffee()
    .pipe gulp.dest cfg.paths.docsource

# ↓ #

# generate documentation (coffee & cjsx)
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

# transform .yml file in src
# to .json file in build
gulp.task "yaml", ->
  gulp.src cfg.paths.yaml
    .pipe plumber()
    .pipe yaml
      space: 2
    .pipe gulp.dest cfg.paths.build

# start server to serve static
gulp.task "webserver", ->
  gulp.src cfg.paths.build
    .pipe plumber()
    .pipe webserver
      fallback: cfg.paths.index_file

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
  ], ["build"]

# build all assets
gulp.task "build", [
  "yaml"
  "bundle"
  "html"
  "codo"
]

# run server (to serve static) and watch changes
gulp.task "serve", ["build"], ->
  gulp.start "webserver"
  gulp.start "watch"

gulp.task "default", [
  "serve"
]
