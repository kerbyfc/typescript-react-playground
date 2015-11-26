var jade = require(`gulp-jade`);

var indexFile = `${dirs.src}/index.jade`;

function buildIndex() {
  return helpers.src(indexFile)
    .pipe(jade())
    .pipe(helpers.save());
}

gulp.task(`index:build`, buildIndex);
gulp.task(`index:serve`, [`index:build`], function() {
  return gulp.watch(indexFile, [`index:build`]);
});

