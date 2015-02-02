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

  # translate Docblockr comments to codo comments
  doc2codo: ->
    replace /(\n[\s]+\#{3}\*)([^\#]+)(\#{3})/g, (m, _s, block, e_) ->
      block = block
        .replace /\{/g, "["
        .replace /\}/g, "]"
        .replace /\s\*/g, "#"
      "\n#{block}#"

  injectScssImports: ->
    replace /(COMPONENTS\n+)(.|\n)*/g, (m, _s, block, e_) ->
      paths = glob.sync p.src.components.styles
      _s + (_.map paths, (p) -> "@import \"#{p}\";").join("\n") + "\n"

################################################################################
# STYLES

gulp.task "scss:inject", ->
  gulp.src p.src.styles
    .pipe pipes.injectScssImports()
    .pipe gulp.dest p.src.base

# compile scss
gulp.task "scss", ["scss:inject"], ->
  gulp.src p.src.styles
    .pipe scss
      includePaths: cfg.scss.includePaths
      onSuccess: (result) ->
        components = glob.sync p.src.components.styles

        if components.length
          target = result.css.slice result.css.indexOf("-component") - 80
          found = _.reduce components, (m, c) ->
            basename = path.basename c, ".scss"
            className = helpers.className basename
            re = ///(\.#{className}([^\}])+)///g
            buf = ""
            while r = re.exec target
              buf += r[0] + "}\n"
            m[c] = buf
            m
          , {}
          for file, css of found
            fs.outputFile(
              file
                .replace p.src.base, p.compiled.base
                .replace 'scss', 'css'
              css
            )

    .pipe replace /\((.*)(\.css)\)/g, "(/../bower_components/$1$2)"
    # import css (import ...css statements bubbles to top)
    .pipe cssimport()
    .pipe gulp.dest p.build.base

gulp.task "styles", ->
  gulp.watch cfg.paths.scss, ["scss:bundle"]

################################################################################
# TEMPLATES

# copy html from src to build
gulp.task "index", ->
  gulp.src p.src.index
    .pipe pipes.notifier()
    .pipe jade()
    .pipe gulp.dest p.build.base

gulp.task "jade", ->
  gulp.src p.src.components.templates
    .pipe pipes.notifier()
    .pipe reactJade()
    .pipe replace /^(.*)/, "module.exports = $1"
    .pipe gulp.dest p.compiled.base

gulp.task "templates", ["index", "jade"], ->
  gulp.watch p.src.index, ["index"]
  gulp.watch p.src.components.templates, ["bundle"]

################################################################################
# SCRIPTS

# compile coffee jsx
gulp.task "cjsx", ->
  gulp.src p.src.scripts
    .pipe pipes.notifier()
    .pipe cjsx
       bare: true
    .pipe gulp.dest p.compiled.base

# ↓ #

# build application bundle with browserify
gulp.task "bundle", ["cjsx", "jade"], ->
  gulp.src p.compiled.bootstrap
    .pipe pipes.notifier()
    .pipe browserify
      paths: helpers.glob cfg.browserify.paths
    .pipe gulp.dest p.build.base

gulp.task "scripts", ["bundle"], ->
  gulp.watch p.src.scripts, ["bundle"]

################################################################################
#  DOCUMENTATION

# translate cjsx to coffee
gulp.task "cjsx2coffee", ->
  gulp.src p.src.scripts
    .pipe pipes.notifier()
    .pipe cjsx2coffee()
    .pipe pipes.doc2codo()
    .pipe gulp.dest p.compiled.base

# ↓ #

# generate documentation for coffee
gulp.task "codo", ["cjsx2coffee"], shell.task [
  "./node_modules/.bin/codo
   --undocumented --closure --private
    #{p.compiled.base} > #{p.nodoc}"
]

# ↓ #

gulp.task "docs", ["codo"], ->
  gulp.watch p.compiled.bootstrap, ["codo"]

################################################################################
# AUTOTESTS

gulp.task "karma", (done) ->
  karma.server.start
      configFile: helpers.fullpath p.karma
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
        path.join p.src.modules, argv.m) or # - in module or ...
          p.src.base # - ... in base

      # relative components dir path
      cfg.paths.common.components
      # component name
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
  gulp.src [ p.src.configs, p.config ]
    .pipe pipes.notifier()
    .pipe yaml
      space: 2
    .pipe tap pickShared
    .pipe gulp.dest p.compiled.base

gulp.task "configs", ["yaml"], ->
  gulp.watch [ p.src.configs, p.config ], ["yaml"]

################################################################################
# SERVING

lrPaths = helpers.fullpath cfg.livereload.paths, cfg.livereload.cwd

# start server to serve static
gulp.task "serve", ->
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
      gulp.src p.compiled.base
    )
    .pipe clean
      read: false

################################################################################
#  MULTITASKS

# build all assets
gulp.task "build", [
  "yaml"
  "bundle"
  "index"
  "jade"
  "scss"
  "codo"
]

# rebuild
gulp.task "rebuild", ["cleanup"], ->
  gulp.start "build"

# build and watch all assets
gulp.task "default", [
  "styles"
  "templates"
  "docs"
  "configs"
  "scripts"
  "serve"
  ]
