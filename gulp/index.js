var yaml       = require(`yamljs`),
    requireDir = require(`require-dir`);
    _          = require(`lodash`);

_.extend(global, {
  _       : _,
  gulp    : require(`gulp`),
  helpers : require(`./helpers.js`),

  dirs: {
    src        : `src`,
    build      : `build`,
    docs       : `docs`,
    styles     : `src/styles`,
    scripts    : `src/scripts`,
    components : `src/scripts/**/components/**/*`
  }
});

requireDir(`./tasks`, {
  recurse: true
});

gulp.task(`build`, [
  `fonts:copy`,
  `images:copy`,
  `yaml:build`,
  `scss:build`,
  `jade:build`,
  `scripts:build`
]);

gulp.task(`serve`, [
  `fonts:copy`,
  `images:copy`,
  `yaml:serve`,
  `scss:serve`,
  `jade:serve`,
  `scripts:serve`,
  `server:run`
]);

gulp.task(`rebuild`, [`cleanup`], function() {
  return gulp.start(`build`);
});
