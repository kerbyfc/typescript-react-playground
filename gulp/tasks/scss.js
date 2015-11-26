var cssimport = require(`gulp-cssimport`),
    scss      = require(`gulp-sass`),
    path      = require(`path`),
    gutil     = require(`gulp-util`),
    replace   = require(`gulp-replace`);

var options = {
  includePaths: helpers.glob([
    `${dirs.styles}/*/`,

    // components should be imported by it's basenames
    dirs.components
  ])
};

var componentsPaths = helpers.glob(`${dirs.components}.scss`),
    cssEntryFile    = `${dirs.styles}/app.scss`;

var all = _.union(componentsPaths, helpers.glob(`${dirs.styles}/**/*.scss`));

function injectComponentStyles() {
  // prepare code block of scss imports
  var imports = _.map(componentsPaths, (_path) => {
    return `@import "${path.basename(_path)}";`
  }).join(`\n`);

  return helpers.src(cssEntryFile)
    // paste imports beetween start and end patterns
    .pipe(helpers.inject(imports, `// <COMPONENTS>`, `// <END>`))

    // write changes to app.scss
    .pipe(helpers.save(`${dirs.styles}`));
};

function buildStyles() {
  gutil.log(`Sass options`, JSON.stringify(options, null, 2));
  return helpers.src(cssEntryFile)
    .pipe(scss(options))
    .pipe(cssimport())
    .pipe(helpers.save());
};

gulp.task(`scss:injectComponents`, injectComponentStyles);
gulp.task(`scss:build`, [`scss:injectComponents`], buildStyles);

gulp.task(`scss:serve`, [`scss:build`], function() {
  return gulp.watch(all, [`scss:build`]);
});
