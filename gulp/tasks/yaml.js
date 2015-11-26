var tap    = require("gulp-tap"),
    yaml   = require("gulp-yaml"),
    wrap   = require("gulp-wrap"),
    concat = require("gulp-concat"),
    rename = require("gulp-rename");

var yamlFiles = `${dirs.src}/**/*.yml`;

function buildYaml() {
  return helpers.src(yamlFiles)
    .pipe(yaml({
      space: 2
    }))
    .pipe(tap(
      (stream) => {
        var content = stream.contents.toString();
        if (content.match(/shared"[\s]*\:/)) {
          try {
            content = JSON.parse(content);
            stream.contents = new Buffer(JSON.stringify(_.pick(c, content.shared), null, 2));
          } catch (_error) {}
        }
        stream.contents = stream.contents.slice(1, stream.contents.length - 1);
        return stream;
    }))
    .pipe(concat("config", { newLine: "," }))
    .pipe(wrap("{<%= contents %>}"))
    .pipe(rename("config.json"))
    .pipe(helpers.save());
};

gulp.task("yaml:build", buildYaml);
gulp.task("yaml:serve", ["yaml:build"], function() {
  return gulp.watch(yamlFiles, ["scripts:build"]);
});
