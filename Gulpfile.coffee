_           = require "lodash"
glob        = require "glob"
path        = require "path"
gulp        = require "gulp"
karma       = require "karma"
YAML        = require "yamljs"
fs          = require "fs-extra"

browserify  = require "gulp-browserify"
jade        = require "gulp-jade"
reactJade   = require "gulp-react-jade"
wrap        = require "gulp-wrap"
rename      = require "gulp-rename"
yaml        = require "gulp-yaml"
replace     = require "gulp-replace"
shell       = require "gulp-shell"
cjsx2coffee = require "gulp-coffee-react-transform"
concat      = require "gulp-concat"
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
debug       = require "gulp-debug"

# get gulp arguments
argv = require "yargs"
  .argv

################################################################################
# CONFIGURATION

cfg = YAML.load "config.yml"

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
            m[k] = path.join p[scope].base, v; m
          , {}
        else
          # join relative and base paths
          path.join p[scope].base, _path

################################################################################
# HELPERS

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

  injectScssImports: ->
    replace /(COMPONENTS\n+)(.|\n)*/g, (m, _s, block, e_) ->
      paths = _.map (glob.sync p.src.components.styles), (p) ->
        name = path.basename p, ".scss"
        "@import '#{path.join name, name}.scss';"
      _s + "\n" + paths.join("\n") + "\n"

################################################################################
# STYLES

gulp.task "scss:inject", ->
  gulp.src p.src.style
    .pipe pipes.injectScssImports()
    .pipe gulp.dest p.src.styles

# compile scss
gulp.task "scss:build", ["scss:inject"], ->
  gulp.src p.src.style
    .pipe pipes.notifier()
    .pipe scss
      includePaths: helpers.glob helpers.fullpath cfg.scss.includePaths
    .pipe replace /\((.*)(\.css)\)/g, "(/../bower_components/$1$2)"
    # import css (import ...css statements bubbles to top)
    .pipe cssimport()
    .pipe gulp.dest p.build.base

gulp.task "scss:serve", ["scss:build"], ->
  gulp.watch p.src.scss, ["scss:build"]

################################################################################
# TEMPLATES

# copy html from src to build
gulp.task "index:build", ->
  gulp.src p.src.index
    .pipe pipes.notifier()
    .pipe jade()
    .pipe gulp.dest p.build.base

accumulateJsx = (stream) ->
  name = path.basename stream.path, "-tmpl.js"
  stream.contents = new Buffer "exports.#{name} = #{stream.contents}"

gulp.task "jade:build", ["index:build"], ->
  gulp.src p.src.components.templates
    .pipe pipes.notifier()
    .pipe reactJade()
    .pipe tap accumulateJsx
    .pipe concat cfg.paths.build.templates, newLine: ";"
    .pipe gulp.dest p.build.base

gulp.task "jade:serve", ["index:build"], ->
  gulp.watch p.src.index, ["index:build"]
  gulp.watch p.src.components.templates, ["scripts:build"]

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
gulp.task "yaml:build", ->
  gulp.src [ p.src.yaml, p.config ]
    .pipe pipes.notifier()
    .pipe yaml
      space: 2
    .pipe tap pickShared
    .pipe gulp.dest p.build.base

gulp.task "yaml:serve", ["yaml:build"], ->
  gulp.watch [ p.src.yaml, p.config ], ["scripts:build"]

################################################################################
# SCRIPTS

# build application bundle with browserify
gulp.task "scripts:build", ["yaml:build", "jade:build"], ->
  gulp.src p.src.bootstrap, read: false
    .pipe pipes.notifier()
    .pipe browserify
      transform  : ['coffeeify']
      extensions : ['.coffee'  ]
      insertGlobals: false
      paths: helpers.glob cfg.browserify.paths
    .pipe rename cfg.paths.build.bootstrap
    .pipe gulp.dest p.build.base

gulp.task "scripts:serve", ["scripts:build"], ->
  gulp.watch p.src.coffee, ["scripts:build"]

################################################################################
#  DOCUMENTATION


gulp.task "codo:theme", shell.task [
  "rm -rf #{path.resolve cfg.codo.theme.link} &&
   cp -fr #{path.resolve cfg.codo.theme.src} #{path.resolve cfg.codo.theme.link}"
]

gulp.task "codo:patch", ->
  gulp.src path.join cfg.codo.lib, "traverser.coffee"
    .pipe replace(
      /\s(\/[^\/]+\/\,\s\"\#\#\#\")/g
      "($1).replace(/\\s\\*/g, '')"
    )
    .pipe gulp.dest cfg.codo.lib

# ↓ #

# generate documentation for coffee
gulp.task "codo:build", ["codo:patch", "codo:theme"], shell.task [
  "./node_modules/.bin/codo
  --undocumented --closure --private
  #{p.src.coffee} -o #{p.docs} > #{p.nodoc}"
]

# ↓ #

gulp.task "codo:serve", ["codo:build"], ->
  gulp.watch p.build.bootstrap, ["codo:build"]

################################################################################
# AUTOTESTS

gulp.task "karma", (done) ->
  karma.server.start
      configFile: helpers.fullpath p.karma
    , done

################################################################################
# SCAFFOLDING

gulp.task "scaffold", ->
  target = switch true
    when argv.c?
      "component"
    else
      false
  if target
    gulp.start "scaffold:#{target}"

gulp.task "scaffold:component", ->

  component = helpers.fullpath path.join [

      # resolve module directory path when -m was passed
      (argv.m and
        path.join p.src.modules, argv.m) or # - in module or ...
          p.src.scripts # - ... in base

      # relative components dir path
      cfg.paths.common.components
      # component name
      argv.c
    ]...
  dir = path.dirname component

  # check components directory existance
  fs.exists dir, (exists) ->
    unless exists
      return console.log "Can't find #{dir}"

    # check if component already exists
    fs.exists component, (ok) ->
      if ok
        if argv.f?
          fs.removeSync component
        else
          return console.log "Component already exists. User -f to override"

      # generate
      fs.mkdir component, (err) ->
        throw err if err

        # basename must be in lower case (convention)
        basename = path.basename component
          .toLowerCase()

        deps = argv.d?
        if deps

          # check dependencynot
          unless _.isString argv.d or argv.d isnt ""
            return console.log "Dependency list is empty"

          deps = argv.d.split(',')
          # transform [btn,link] to {Btn:btn,Link:link}
          deps = _.object _.map(_.clone(deps), helpers.compName), deps

        # use all component templates, defined in config
        for tpl in cfg.scaffold.component
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
# SERVING

lrPaths = helpers.fullpath cfg.livereload.paths, cfg.livereload.cwd

# start server to serve static
gulp.task "server:run", ->
  gulp.src p.build.base
    .pipe webserver
      livereload:
        enable: cfg.livereload.enable
        filter: (file) ->
          file in lrPaths
      fallback: p.build.index

################################################################################
# MISC

gulp.task "cleanup", ->
  merge(
      gulp.src p.build.base
      gulp.src p.docs
    )
    .pipe clean
      read: false

gulp.task "fonts:copy", shell.task [
  "mkdir -p #{p.build.fonts} && cp -r #{p.src.fonts} #{p.build.fonts}"
]

gulp.task "images:copy", shell.task [
  "mkdir -p #{p.build.images} && cp -r #{p.src.images} #{p.build.images}"
]

################################################################################
#  MULTITASKS

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
