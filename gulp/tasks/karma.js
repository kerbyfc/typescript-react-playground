var karma = require("karma");

gulp.task("karma", function(done) {
  return karma.server.start({
    configFile: helpers.fullpath(`${dirs.test}/karma.js`)
  }, done);
});
