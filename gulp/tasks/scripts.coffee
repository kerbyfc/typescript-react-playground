browserify  = require "gulp-browserify"
rename      = require "gulp-rename"
coffeify    = require "coffeeify"

# build application bundle with browserify
gulp.task "scripts:build", ["yaml:build", "jade:build"], ->
  src p.src.bootstrap, read: false
    .pipe browserify
      debug: !gulp.env.production
      transform  : ['coffeeify']
      extensions : ['.coffee'  ]
      insertGlobals: false
      paths: helpers.glob cfg.browserify.paths
    .pipe rename cfg.paths.build.bootstrap
    .pipe save()

gulp.task "scripts:serve", ["scripts:build"], ->
  gulp.watch p.src.coffee, ["scripts:build"]
