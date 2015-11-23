var typedoc = require("gulp-typedoc");

gulp.task("typedoc", function() {
  return gulp
      .src(["src/scripts/**/*.ts"])
      .pipe(typedoc({
          module: "commonjs",
          target: "es5",
          out: "docs/",
          name: "My project title"
      }));
});
