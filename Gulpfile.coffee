_           = require "lodash"
glob        = require "glob"
path        = require "path"
gulp        = require "gulp"
karma       = require "karma"
YAML        = require "yamljs"
fs          = require "fs-extra"

browserify  = require "gulp-browserify"
jade        = require "gulp-react-jade"
rename      = require "gulp-rename"
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
template    = require "gulp-template"

# get gulp arguments
argv = require "yargs"
  .argv

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

  # form ComponentName based on directory_name
  compName: (dirname) ->
    dirname.split "_"
      .map (chunk) ->
        _.capitalize chunk
      .join ""

  className: (dirname) ->
    dirname.replace(/\_/g, '-') + cfg.component.classNameSuffix

pipes =

  # notify about error with growl
  notifier: ->
    plumber
      errorHandler: notify.onError "Error: <%= error.message %>
        \n <%= error.stack %>"

  # translate Docblockr comments to codo comments
  doc2codo: ->
    replace /(\n[\s]+\#{3}\*)([^\#]+)(\#{3})/g, (m, _s, block, e_) ->
      block = block
        .replace /\{/g, "["
        .replace /\}/g, "]"
        .replace /\s\*/g, "#"
      "\n#{block}#"

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
    .pipe pipes.notifier()
    .pipe gulp.dest cfg.paths.build

gulp.task "jade", ->
  gulp.src cfg.paths.jade
    .pipe pipes.notifier()
    .pipe jade()
    .pipe replace /^(.*)/, "module.exports = $1"
    .pipe gulp.dest cfg.paths.compiled

gulp.task "templates", ["html", "jade"], ->
  gulp.watch cfg.paths.html, ["html"]
  gulp.watch cfg.paths.jade, ["bundle"]

################################################################################
# SCRIPTS

# compile coffee jsx
gulp.task "cjsx", ->
  gulp.src cfg.paths.coffee
    .pipe pipes.notifier()
    .pipe cjsx
       bare: true
    .pipe gulp.dest cfg.paths.compiled

# ↓ #

# build application bundle with browserify
gulp.task "bundle", ["cjsx", "jade"], ->
  gulp.src cfg.paths.bootstrap
    .pipe pipes.notifier()
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
    .pipe pipes.notifier()
    .pipe cjsx2coffee()
    .pipe pipes.doc2codo()
    .pipe gulp.dest cfg.paths.compiled

# ↓ #

# generate documentation for coffee
gulp.task "codo", ["cjsx2coffee"], shell.task [
  "./node_modules/.bin/codo
   --undocumented --closure
    #{cfg.paths.compiled} > #{cfg.paths.nodoc}"
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
# GENERATORS

gulp.task "generate", ->
  target = switch true
    when argv.c?
      "component"
    else
      false
  if target
    gulp.start "generate:#{target}"

gulp.task "generate:component", ->

  component = helpers.fullpath path.join [
      # resolve module directory path when -m was passed
      (argv.m and
        path.join cfg.paths.modules, argv.m) or # - in module
          cfg.paths.src # - in base

      # relative components dir path
      cfg.paths.components_dir
      argv.c
    ]...
  dir = path.dirname component

  # check components directory existance
  fs.exists dir, (exists) ->
    unless exists
      return console.log "Can't find #{dir}}"

    # check if component already exists
    fs.exists component, (ok) ->
      if ok
        if argv.f?
          fs.removeSync component
        else
          return console.log "Component already exists"

      # generate
      fs.mkdir component, (err) ->
        throw err if err

        # basename must be in lower case (convention)
        basename = path.basename component
          .toLowerCase()

        deps = argv.d?
        if deps
          deps = argv.d.split(',')
          # transform [btn,link] to {Btn:btn,Link:link}
          deps = _.object _.map(_.clone(deps), helpers.compName), deps

        # use all component templates, defined in config
        for tpl in cfg.templates.component
          gulp.src tpl
            .pipe template
              component : helpers.compName basename
              classname : helpers.className basename
              filename  : basename
              complete  : argv.complete?
              deps      : deps
            .pipe rename
              basename: basename
            .pipe gulp.dest component

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
    .pipe pipes.notifier()
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
