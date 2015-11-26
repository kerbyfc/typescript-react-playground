var plumber = require(`gulp-plumber`),
    replace = require(`gulp-replace`),
    notify  = require(`gulp-notify`),
    glob    = require(`glob`),
    path    = require(`path`);

/*
 * Resolve absolute path for current working directory
 * for one file or for array of files
 */
function absolute(_path, cwd) {
  cwd = cwd || process.cwd();

  if (_.isArray(_path)) {
    return _.map(_path, function(entry){
      return absolute(entry, cwd);
    });

  } else {
    return path.resolve(cwd, _path);
  }
};

/*
 * Extract array of paths from array of paths and path patterns
 * @example glob(['src/app.js', 'src/models/*.js']);
 */
function _glob(paths, options) {
  options = options || {absolute: true};
  if (!_.isArray(paths)) {
    paths = [paths];
  }
  return _(paths)
    .map((_path) => {
      if (_.contains(_path, `*`)) {
        _path = glob.sync(_path);
      };

      if (options.absolute) {
        _path = absolute(_path);
      };

      return _path;
    })
    .flatten()
    .compact()
    .value()
};

/*
 * Pipeline helper to inject content into
 * buffer between two passed patterns. Use it when content
 * between two patterns should be replaced
 * (when source and build files are the same)
 * @example inject(projectTodoContent, `#### TODOs:`, `#### `);
 */
function inject(injection, afterPattern, beforePattern) {
  var pattern = RegExp(`(${afterPattern})((?!${beforePattern}).|\\n)+`, `g`);
  return replace(pattern, `$1\n` + injection + `$2\n`);
};

/*
 * Get React component class name by filename
 * @example my_component -> MyComponent
 */
function componentName(fileBaseName) {
  return fileBaseName.split(`_`).map(_.capitalize).join(``);
};

/*
 * Get class name by component name
 * @example simple_button -> simple-button-component
 */
function cssClassName(fileBaseName) {
  return fileBaseName.replace(/\_/g, '-') + `-component`;
};

function src() {
  var source;
  source = gulp.src.apply(gulp, arguments);
  return source.pipe(plumber({
    errorHandler: notify.onError(`Error: <%= error.message %> \n <%= error.stack %>`)
  }));
};

function save() {
  if (arguments.length) {
    return gulp.dest.apply(gulp, arguments);

  } else {
    return gulp.dest(dirs.build);
  }
};

module.exports = {
  inject        : inject,
  glob          : _glob,
  absolute      : absolute,
  cssClassName  : cssClassName,
  componentName : componentName,
  save          : save,
  src           : src
};
