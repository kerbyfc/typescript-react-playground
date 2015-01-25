_           = require "lodash"
glob        = require "glob"
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
scss        = require "gulp-sass"
merge       = require "gulp-merge"
cssimport   = require "gulp-cssimport"


################################################################################
# HELPERS

cfg = YAML.load "config.yml"

helpers =

  fullpath: (_path, cwd = process.cwd()) ->
    if _.isArray _path
      return ( for entry in _path
        helpers.fullpath entry, cwd )
    path.resolve cwd, _path

  stripLibs: (paths...) ->
    _.flatten ["!node_modules/**", "!bower_components/**", paths]

  glob: (paths) ->
    _paths = for _path in _.clone(paths)
      if _.contains _path, "*"
        glob.sync _path
      else
        _path
    _.flatten _paths

gulp.task "test", ->
  gulp.src "./src/framework/component.coffee"

notifier = ->
  plumber
    errorHandler: notify.onError "Error: <%= error.message %>"

################################################################################
# STYLES

# compile scss
gulp.task "scss", ->
  gulp.src cfg.paths.scss_bootstrap
    .pipe scss
        includePaths: cfg.scss.includePaths
    .pipe replace /\((.*)(\.css)\)/g, "(/../bower_components/$1$2)"
    .pipe cssimport()
    .pipe gulp.dest cfg.paths.build

gulp.task "styles", ["scss"], ->
  gulp.src cfg.paths.scss, ["scss"]

################################################################################
# TEMPLATES

# copy html from src to build
gulp.task "html", ->
  gulp.src cfg.paths.html
    .pipe notifier()
    .pipe gulp.dest cfg.paths.build

gulp.task "templates", ["html"], ->
  gulp.watch cfg.paths.html, ["html"]

################################################################################
# SCRIPTS

# compile coffee jsx
gulp.task "cjsx", ->
  gulp.src cfg.paths.coffee
    .pipe notifier()
    .pipe replace /(\n[\s]+\#{3}\*)([^\#]+)(\#{3})/g, (match, reg, block, end) ->
      block = block
        .replace /\{/g, "["
        .replace /\}/g, "]"
        .replace /\s\*/g, "#"
      "\n#{block}#"
    .pipe gulp.dest cfg.paths.src
    .pipe cjsx
       bare: true
    .pipe gulp.dest cfg.paths.compiled

# ↓ #

# build application bundle with browserify
gulp.task "bundle", ["cjsx"], ->
  gulp.src cfg.paths.bootstrap
    .pipe notifier()
    .pipe browserify
       paths: helpers.glob cfg.browserify.paths
    .pipe gulp.dest cfg.paths.build

gulp.task "scripts", ["bundle"], ->
  gulp.watch cfg.paths.coffee, ["bundle"]

################################################################################
#  DOCUMENTATION

# translate cjsx to coffee
gulp.task "cjsx2coffee", ->
  gulp.src cfg.paths.coffee
    .pipe notifier()
    .pipe cjsx2coffee()
    .pipe gulp.dest cfg.paths.compiled

# ↓ #

# generate documentation for coffee
gulp.task "codo", ["cjsx2coffee"], shell.task [
  "./node_modules/.bin/codo --undocumented --closure #{cfg.paths.compiled} > #{cfg.paths.nodoc}"
]

# ↓ #

gulp.task "docs", ["codo"], ->
  gulp.watch cfg.paths.bootstrap, ["codo"]

################################################################################
# AUTOTESTS

gulp.task "karma", (done) ->
  karma.server.start
      configFile: helpers.fullpath cfg.paths.karma
    , done

################################################################################
# CONFIGS

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
    .pipe notifier()
    .pipe yaml
      space: 2
    .pipe tap pickShared
    .pipe gulp.dest cfg.paths.compiled

gulp.task "configs", ["yaml"], ->
  gulp.watch cfg.paths.yaml, ["yaml"]

################################################################################
# SERVING

lrPaths = helpers.fullpath cfg.livereload.paths, cfg.livereload.cwd

# start server to serve static
gulp.task "serve", ->
  gulp.src cfg.paths.build
    .pipe webserver
      livereload:
        enable: cfg.livereload.enable
        filter: (file) ->
          file in lrPaths
      fallback: cfg.paths.index_file

################################################################################
# MISC

gulp.task "cleanup", ->
  merge(
      gulp.src cfg.paths.build
      gulp.src cfg.paths.compiled
    )
    .pipe clean
      read: false

################################################################################
#  MULTITASKS

# watch changes
gulp.task "watch", ->
  paths =
    yaml      : "yaml"
    coffee    : "bundle"
    html      : "html"
    bootstrap : "codo"
    scss      : "scss"
  for _paths, tasks of paths
    gulp.watch(
      # remove extra dirs
      helpers.stripLibs cfg.paths[_paths]
      tasks.split ","
    )

# build all assets
gulp.task "build", [
  "yaml"
  "bundle"
  "html"
  "scss"
  "codo"
]

gulp.task "default", [
  "styles"
  "templates"
  "docs"
  "configs"
  "scripts"
  "serve"
  ]
