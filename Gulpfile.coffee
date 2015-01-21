path        = require 'path'
gulp        = require "gulp"
browserify  = require "gulp-browserify"
yaml        = require "gulp-yaml"
replace     = require "gulp-replace"
shell       = require "gulp-shell"
cjsx2coffee = require "gulp-coffee-react-transform"
plumber     = require "gulp-plumber"
cjsx        = require "gulp-cjsx"
install     = require "gulp-install"
notify      = require "gulp-notify"
webserver   = require "gulp-webserver"

# source paths
paths =
  js        : [ "./build/**/*.js"   ]
  coffee    : [ "./src/**/*.coffee" ]
  html      : [ "./src/*.html"      ]
  yaml      : [ "./src/**/*.yml"    ]

  docsource : "./doc/sources"


# RegExp to strip long paths for codo (.nodoc)
codoNoDocRe = new RegExp path.resolve(process.cwd(), paths.docsource) + "/", "g"

gulp.task "cjsx", ->
  gulp.src(paths.coffee).pipe(plumber()).pipe(cjsx(bare: true)).pipe gulp.dest("./build")

gulp.task "bundle", ["cjsx"], ->
  gulp.src "./build/bootstrap.js"
    .pipe plumber()
    .pipe browserify(

      paths: [
        "./build"
        "./build/framework"
        "./node_modules"
        "./bower_components"
        "./bower_components/react"
        "./bower_components/react-router/dist/"
      ]

      shim:
        jquery:
          path    : "./bower_components/jquery/dist/jquery.js"
          exports : "jquery"
        lodash:
          path    : "./bower_components/lodash/dist/lodash.js"
          exports : "_"

    .pipe gulp.dest "build"

# copy html from src to build
gulp.task "html", ->
  gulp.src "./src/*.html"
    .pipe plumber()
    .pipe gulp.dest "./build"

# transform .yml file in src
# to .json file in build
gulp.task "config", ->
  gulp.src "./src/config.yml"
    .pipe plumber()
    .pipe yaml
      space: 2
    .pipe gulp.dest "./build"

# install bower and npm packages
gulp.task "install", ->
  gulp.src [
      "./bower.json"
      "./package.json"
    ]
    .pipe plumber()
    .pipe install()

gulp.task "init", ["install"], ->
  gulp.src [
      "./bower.json"
      "./package.json"
    ]
    .pipe plumber()

gulp.task "transform", ->
  gulp.src "./src/**/*.coffee", read: false
    .pipe plumber()
    .pipe shell([
        "echo <%= f(file.path) %>"
      ],
      templatedata:
        f: (s) ->
          s.replace /$/, ".bak"
    )

gulp.task "cleanupdocsources", shell.task(["rm -rf #{paths.docs}"])

gulp.task "cjsx2coffee", ["cleanupdocsources"], ->
  gulp.src(paths.coffee).pipe(plumber()).pipe(cjsx2coffee()).pipe gulp.dest(paths.docsource)

# generate documentation (coffee & cjsx)
gulp.task "codo", ["cjsx2coffee"], shell.task [
  "./node_modules/.bin/codo --undocumented --closure #{paths.docsource} > .nodoc"
]

# generate documentation
# and form .nodoc file (undocumented methods/classes)
gulp.task "gendoc", ["codo"], ->
  gulp.src ".nodoc"
    .pipe replace /\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/g, ''
    .pipe replace codoNoDocRe, ''
    .pipe replace /[│├┌┬┼┐┤┤┴└─┘]/g, ''
    .pipe replace /\n{1,2}\s/g, '\n'
    .pipe gulp.dest './'

# start server to serve static
gulp.task "webserver", ->
  gulp.src("build").pipe(plumber()).pipe webserver(
    fallback: "index.html"
    livereload: true
    directorylisting: true
  )

# watch changes
gulp.task "watch", ->
  gulp.watch [
    "src/**/*.coffee"
    "src/**/*.html"
    "src/**/*.yaml"
    "src/**/*.yml"
    "!node_modules"
    "!bower_components"
  ], ["build"]

# build all assets
gulp.task "build", [
  "config"
  "bundle"
  "html"
  "gendoc"
]

# run server (to serve static) and watch changes
gulp.task "serve", ["build"], ->
  gulp.start "watch"

# check npm/bower mods changes and serve
gulp.task "default", ["init"], ->
  gulp.start "serve"
