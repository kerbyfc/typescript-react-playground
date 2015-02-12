rename     = require "gulp-rename"
through    = require "through2"
browserify = require "browserify"
coffeeify  = require "coffeeify"

# build application bundle with browserify
gulp.task "scripts:build", ["yaml:build", "jade:build"], ->
  bundle = browserify
    entries: p.src.bootstrap
    extensions: [".coffee", ".json", ".js"]
    paths: helpers.glob cfg.browserify.paths
  .bundle()
  .pipe FS.createWriteStream p.build.bootstrap

  # src p.src.bootstrap, read: false
  #   .pipe browserify
  #     debug: !gulp.env.production
  #     transform  : ['coffeeify']
  #     extensions : ['.coffee'  ]
  #     insertGlobals: false
  #     paths: helpers.glob cfg.browserify.paths
  #   .pipe rename cfg.paths.build.bootstrap
  #   .pipe save()

gulp.task "scripts:serve", ["scripts:build"], ->
  gulp.watch p.src.coffee, ["scripts:build"]
