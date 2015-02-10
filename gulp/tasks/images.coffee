shell = require "gulp-shell"

gulp.task "images:copy", shell.task [
  "mkdir -p #{p.build.images} && cp -r #{p.src.images} #{p.build.images}"
]
