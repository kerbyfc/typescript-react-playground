var todo    = require("gulp-todo"),
    tap     = require("gulp-tap"),
    replace = require("gulp-replace"),
    merge   = require("gulp-merge");

gulp.task("todo:all", function() {
  return merge(src(p.src.coffee), src(p.src.scss), src(p.src.components.templates)).pipe(todo({
    fileName: "todo.json",
    reporter: "json"
  })).pipe(tap(function(buffer) {
    var items, tasks;
    items = JSON.parse(String(buffer.contents));
    if (!_.isNull(items)) {
      tasks = _.map(items, function(item) {
        return new Promise(function(resolve, reject) {
          var base, ext, path;
          ext = PATH.extname(item.file).slice(1);
          base = (function() {
            switch (ext) {
              case "scss":
                return p.src.styles;
              default:
                return p.src.scripts;
            }
          })();
          path = PATH.resolve(base, item.file);
          return FS.readFile(path, function(err, data) {
            if (err) {
              throw err;
            }
            return resolve(_.extend(item, {
              content: String(data),
              ext: ext
            }));
          });
        });
      });
      Promise.all(tasks).then(function(files) {
        var content, contents, f, i, j, kind, len, len1, readme, ref, ref1, rows;
        readme = src(p.readme);
        contents = "";
        ref = ["TODO", "FIXME"];
        for (i = 0, len = ref.length; i < len; i++) {
          kind = ref[i];
          content = "";
          ref1 = _.where(files, {
            kind: kind
          });
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            f = ref1[j];
            if (f.content) {
              rows = f.content.split("\n");
              content += "***" + f.file + "*** \n" + f.text + "\n```" + f.ext + " \n" + (rows.slice(f.line - 3, f.line + 6).join("\n")) + "\n```\n\n";
            }
          }
          readme.pipe(helpers.inject(content, "### " + kind + "s", "###"));
        }
        return readme.pipe(gulp.dest(p.root));
      });
      return buffer;
    }
  }));
});
