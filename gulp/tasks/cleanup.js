var merge = require("gulp-merge"),
    del   = require("del");

gulp.task("cleanup", function() {
  return del([src(p.build.base), src(p.docs)]);
});
