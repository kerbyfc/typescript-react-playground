var sourcemaps = require("gulp-sourcemaps"),
    tsify      = require("tsify"),
    browserify = require("browserify"),
    source     = require("vinyl-source-stream"),
    watchify   = require("watchify"),
    buffer     = require("vinyl-buffer"),
    gutil      = require("gulp-util"),
    coffeeify  = require("coffeeify");

// Gulp process instance bundler instance,
// that can be created by "scripts:serve" task
var bundler;

// Browserify options
var options = {
  debug      : true,
  entries    : ["src/scripts/app.ts"],
  extensions : [".ts", ".coffee"],

  paths: [
    "src/scripts",
    "src/scripts/core",
    "build"
  ]
};

function createBundler(options, watch) {
  if (options == null) {
    options = {};
  };

  // Cut of watch option and merge watchify options
  if (watch) {
    options = _.extend({}, options, watchify.args);
  };

  var _bundler = browserify(options);

  // Additional wrapping and parametrizing for watchify
  if (watch) {
    _bundler = watchify(_bundler);
    _bundler.on("update", bundle);
  };

  _bundler.on("log", gutil.log);

  // Add plugins
  _bundler
    .plugin(tsify, {})
    .plugin(coffeeify, {});

  if (watch) {
    bundle({bundler: _bundler});
  };

  return _bundler;
};

function bundle(options) {
  // Use bundler, created by "scripts:serve" task
  // or create new one to bundle once
  var _bundler = bundler || options.bundler || createBundler(options);

  return _bundler.bundle()
    // Get compiled entry
    .pipe(source(p.bootstrap))
    .pipe(buffer())

    // Apply source maps
    .pipe(sourcemaps.init({loadMaps: true}))
    .pipe(sourcemaps.write("./"))

    // Save
    .pipe(gulp.dest(p.build.base));
};

gulp.task("scripts:serve", ["yaml:build"], function(){
  bundler = createBundler(options, true);
});

gulp.task("scripts:build", ["yaml:build"], function(){
  return bundle(options);
});
