merge = require "gulp-merge"
clean = require "gulp-clean"

gulp.task "cleanup", ->
  merge(
      src p.build.base
      src p.docs
    )
    .pipe clean
      read: false
