var webserver = require("gulp-webserver");

var files = helpers.glob([
  `${dirs.build}/app.js`,
  `${dirs.build}/app.css`,
  `${dirs.build}/templates.js`,
  `${dirs.build}/index.html`,
  `${dirs.build}/config.json`
]);

var options = {
  fallback: `${dirs.build}/index.html`,

  livereload: {
    enable: true,

    filter: (file) =>
      _.indexOf(files, file) >= 0
  }
};

gulp.task("server:run", function() {
  return helpers.src(dirs.build)
    .pipe(webserver(options));
});
