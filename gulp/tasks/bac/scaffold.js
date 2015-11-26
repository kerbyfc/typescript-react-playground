var rename = require("gulp-rename"),
    template = require("gulp-template"),
    argv = require("yargs").argv;

gulp.task("scaffold", function() {
  var target;
  target = (function() {
    switch (true) {
      case argv.c != null:
        return "component";
      default:
        return false;
    }
  })();
  if (target) {
    return gulp.start("scaffold:" + target);
  }
});

gulp.task("scaffold:component", function() {
  var component, dir;
  component = helpers.fullpath(PATH.join.apply(PATH, [(argv.m && PATH.join(p.src.modules, argv.m)) || p.src.scripts, cfg.paths.common.components, argv.c]));
  dir = PATH.dirname(component);
  return fs.exists(dir, function(exists) {
    if (!exists) {
      return console.log("Can't find " + dir);
    }
    return fs.exists(component, function(ok) {
      if (ok) {
        if (argv.f != null) {
          fs.removeSync(component);
        } else {
          return console.log("Component already exists. User -f to override");
        }
      }
      return fs.mkdir(component, function(err) {
        var basename, deps, i, len, ref, results, tpl;
        if (err) {
          throw err;
        }
        basename = PATH.basename(component).toLowerCase();
        deps = argv.d != null;
        if (deps) {
          if (!_.isString(argv.d || argv.d !== "")) {
            return console.log("Dependency list is empty");
          }
          deps = argv.d.split(',');
          deps = _.object(_.map(_.clone(deps), helpers.componentName), deps);
        }
        ref = cfg.scaffold.component;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          tpl = ref[i];
          results.push(src(tpl).pipe(template({
            component: helpers.componentName(basename),
            classname: helpers.cssClassName(basename),
            filename: basename,
            complete: argv.complete != null,
            deps: deps
          })).pipe(rename({
            basename: basename
          })).pipe(gulp.dest(component)));
        }
        return results;
      });
    });
  });
});
