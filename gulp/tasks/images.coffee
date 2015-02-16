shell = require "gulp-shell"

gulp.task "images:copy", shell.task [
  "rm -rf #{p.build.images} && cp -r #{p.src.images} #{p.build.base}"
]
