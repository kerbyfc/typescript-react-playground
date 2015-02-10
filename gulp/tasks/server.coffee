webserver   = require "gulp-webserver"

lrPaths = helpers.fullpath cfg.livereload.paths, cfg.livereload.cwd

# start server to serve static
gulp.task "server:run", ->
  src p.build.base
    .pipe webserver
      livereload:
        enable: cfg.livereload.enable
        filter: (file) ->
          file in lrPaths
      fallback: p.build.index
