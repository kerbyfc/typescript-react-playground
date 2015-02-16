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

gulp.task "scripts:serve", ["scripts:build"], ->
  gulp.watch p.src.coffee, ["scripts:build"]
