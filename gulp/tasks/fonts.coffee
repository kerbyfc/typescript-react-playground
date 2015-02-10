shell = require "gulp-shell"

gulp.task "fonts:copy", shell.task [
  "mkdir -p #{p.build.fonts} && cp -r #{p.src.fonts} #{p.build.fonts}"
]
