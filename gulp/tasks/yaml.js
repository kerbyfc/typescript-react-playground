var tap    = require("gulp-tap"),
    yaml   = require("gulp-yaml"),
    wrap   = require("gulp-wrap"),
    concat = require("gulp-concat"),
    rename = require("gulp-rename");

gulp.task("yaml:build", function() {
  return src(p.src.yaml).pipe(yaml({
    space: 2
  })).pipe(tap(function(buf) {
    var c;
    c = buf.contents.toString();
    if (c.match(/shared"[\s]*\:/)) {
      try {
        c = JSON.parse(c);
        buf.contents = new Buffer(JSON.stringify(_.pick(c, c.shared), null, 2));
      } catch (_error) {}
    }
    buf.contents = buf.contents.slice(1, buf.contents.length - 1);
    return buf;
  })).pipe(concat("config", {
    newLine: ","
  })).pipe(wrap("{<%= contents %>}")).pipe(rename("config.json")).pipe(save());
});

gulp.task("yaml:serve", ["yaml:build"], function() {
  return gulp.watch(p.src.yaml, ["scripts:build"]);
});
