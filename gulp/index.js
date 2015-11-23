var _path, key, notify, p, paths, plumber, ref, ref1, requireDir, requirements, scope;

requireDir = require("require-dir");

plumber = require("gulp-plumber");

notify = require("gulp-notify");

requirements = {
  gulp: require("gulp"),
  _: require("lodash"),
  GLOB: require("glob"),
  PATH: require("path"),
  FS: require("fs-extra"),
  YAML: require("yamljs")
};

requirements._.extend(global, requirements, {
  helpers: require("./helpers.js")
});

global.cfg = YAML.load("./gulp/config.yml");

p = {};

ref = cfg.paths;
for (scope in ref) {
  paths = ref[scope];
  p[scope] = _.clone(paths);
  if (_.isObject(paths) && _.has(paths, 'base')) {
    ref1 = p[scope];
    for (key in ref1) {
      _path = ref1[key];
      if (key !== 'base') {
        p[scope][key] = _.isObject(_path) ? _.reduce(_path, function(m, v, k) {
          m[k] = PATH.join(p[scope].base, v);
          return m;
        }, {}) : PATH.resolve(p[scope].base, _path);
      }
    }
  }
}

_.extend(global, {
  p: p,
  src: function() {
    var source;
    source = gulp.src.apply(gulp, arguments);
    return source.pipe(plumber({
      errorHandler: notify.onError("Error: <%= error.message %> \n <%= error.stack %>")
    }));
  },
  save: function() {
    if (arguments.length) {
      return gulp.dest.apply(gulp, arguments);
    } else {
      return gulp.dest(p.build.base);
    }
  }
});

requireDir("./tasks", {
  recurse: true
});

gulp.task("build", ["fonts:copy", "images:copy", "yaml:build", "scss:build", "jade:build", "scripts:build"]);

gulp.task("rebuild", ["cleanup"], function() {
  return gulp.start("build");
});

gulp.task("default", ["fonts:copy", "images:copy", "yaml:serve", "scss:serve", "jade:serve", "scripts:serve", "server:run"]);
