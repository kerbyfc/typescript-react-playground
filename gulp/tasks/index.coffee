jade = require "gulp-jade"

# copy html from src to build
gulp.task "index:build", ->
  src p.src.index
    .pipe jade()
    .pipe save()

gulp.task "index:serve", ["index:build"], ->
  gulp.watch p.src.index, ["index:build"]


