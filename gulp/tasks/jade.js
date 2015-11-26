var concat = require(`gulp-concat`),
    path   = require(`path`),
    tap    = require(`gulp-tap`);

var templates = `${dirs.components}.jade`

function buildTemplates() {
  return helpers.src(templates)
    .pipe(jade())
    .pipe(tap(
      (stream) => {
        var name = path.basename(stream.path, `-tmpl.js`);
        return stream.contents = new Buffer(`exports.${name} = ${stream.contents}`);
      }
    ))
    .pipe(concat(`${dirs.build}/templates.js`, { newLine: `` }))
    .pipe(helpers.save());
}

gulp.task(`jade:build`, [`index:build`], buildTemplates);
gulp.task(`jade:serve`, [`index:build`], function() {
  return gulp.watch(templates, [`scripts:build`]);
});
