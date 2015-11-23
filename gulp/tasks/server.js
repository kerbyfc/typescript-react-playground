var webserver = require("gulp-webserver"),
    liveReloadSource = helpers.fullpath(cfg.livereload.paths, cfg.livereload.cwd);

var options = {
  fallback: p.build.index,

  livereload: {
    enable: cfg.livereload.enable,

    filter: function(file) {
      return _.indexOf(liveReloadSource, file) >= 0;
    }
  }
};

gulp.task("server:run", function() {
  return src(p.build.base)
    .pipe(webserver(options));
});
