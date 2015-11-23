var plumber = require("gulp-plumber"),
    replace = require("gulp-replace"),
    GLOB    = require("glob"),
    PATH    = require("path");

/*
 * Resolve absolute path for current working directory
 * for one file or for array of files
 */
function fullpath(path, cwd) {
  if (cwd == null) {
    cwd = cwd || process.cwd();
  }
  if (_.isArray(path)) {
    return _.map(path, function(entry){
      return fullpath(entry, cwd);
    });
  } else {
    PATH.resolve(cwd, path);
  }
};

/*
 * Extract array of paths from array of paths and path patterns
 * @example glob(['src/app.js', 'src/models/*.js']);
 */
function glob(paths) {
  return _.flatten(_.map(paths, path) {
    return _.contains(_path, "*") ? GLOB.sync(_path) : _path;
  });
};

/*
 * Pipeline helper to inject content into
 * buffer between two passed patterns. Use it when content
 * between two patterns should be replaced
 * (when source and build files are the same)
 * @example inject(projectTodoContent, "#### TODOs:", "#### ");
 */
function inject(injection, afterPattern, beforePattern) {
  var pattern = RegExp("(" + afterPattern + ")((?!" + beforePattern + ").|\\n)+", "g");
  return replace(pattern, "$1\n" + injection + "$2\n");
};

/*
 * Get React component class name by filename
 * @example my_component -> MyComponent
 */
function componentName(fileBaseName) {
  return fileBaseName.split("_").map(_.capitalize).join("");
};

/*
 * Get class name by component name
 * @example simple_button -> simple-button-component
 */
function cssClassName(fileBaseName) {
  return fileBaseName.replace(/\_/g, '-') + "-component";
};

module.exports = {
  inject        : inject,
  glob          : glob,
  fullpath      : fullpath,
  cssClassName  : cssClassName,
  componentName : componentName
};
