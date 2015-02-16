shell = require "gulp-shell"

gulp.task "fonts:copy", shell.task [
  "rm -rf #{p.build.fonts} && cp -r #{p.src.fonts} #{p.build.base}"
]
