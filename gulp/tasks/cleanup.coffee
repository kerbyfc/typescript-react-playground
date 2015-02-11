merge = require "gulp-merge"
del   = require "del"

gulp.task "cleanup", ->
  del [
    src p.build.base
    src p.docs
  ]
