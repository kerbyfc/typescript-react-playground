shell = require(`shelljs`);

gulp.task(`images:copy`, function(done) {
  shell.rm(`-rf`, `${dirs.build}/images`);
  shell.cp(`-r`, `${dirs.src}/images`, `${dirs.build}/images`);
  done();
});
