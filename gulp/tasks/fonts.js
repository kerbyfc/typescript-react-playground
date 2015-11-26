var shell = require(`shelljs`);

gulp.task(`fonts:copy`, function(done) {
  shell.rm(`-rf`, `${dirs.build}/fonts`);
  shell.cp(`-r`, `${dirs.src}/fonts`, `${dirs.build}/fonts`);
  done();
});
