jade   = require "gulp-react-jade"
concat = require "gulp-concat"
tap    = require "gulp-tap"

gulp.task "jade:build", ["index:build"], ->
  src p.src.components.templates
    .pipe jade()
    .pipe tap (stream) ->
      name = PATH.basename stream.path, "-tmpl.js"
      stream.contents = new Buffer "exports.#{name} = #{stream.contents}"
    .pipe concat cfg.paths.build.templates, newLine: ";"
    .pipe save()

gulp.task "jade:serve", ["index:build"], ->
  gulp.watch p.src.components.templates, ["scripts:build"]
