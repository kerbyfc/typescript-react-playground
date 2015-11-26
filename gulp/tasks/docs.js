var typedoc = require(`gulp-typedoc`);

gulp.task(`typedoc`, function() {
  shell.rm(`-rf`, dirs.docs);
  return gulp.src(`${dirs.scripts}/**/*.ts`)
    .pipe(typedoc({
        // TODO: options
        module : `commonjs`,
        target : `es5`,
        out    : dirs.docs,
        name   : `Traffic Monitor`
    }));
});
