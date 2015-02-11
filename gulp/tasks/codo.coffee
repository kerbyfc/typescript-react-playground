shell    = require "gulp-shell"
replace  = require "gulp-replace"

gulp.task "codo:theme", shell.task [
  "rm -rf #{PATH.resolve cfg.codo.theme.link} &&
   cp -fr #{PATH.resolve cfg.codo.theme.src} #{PATH.resolve cfg.codo.theme.link}"
]

gulp.task "codo:patch", ->
  src PATH.join cfg.codo.lib, "traverser.coffee"
    .pipe replace(
      /\s(\/[^\/]+\/\,\s\"\#\#\#\")/g
      "($1).replace(/\\s\\*/g, '')"
    )
    .pipe gulp.dest cfg.codo.lib

gulp.task "codo:build", ["codo:patch", "codo:theme"], shell.task [
  "node_modules/.bin/codo
  --undocumented --closure --private
  #{p.src.scripts} -o #{p.docs}
  | perl -pe 's/\\x1b\\[[0-9;]*m//g'
  | sed 's/#{PATH.resolve(p.src.scripts).replace /\//g, '\\/'}//'
  | sed 's/[│├┌┬┼┐┤┤┘┴└─]//g'
  | perl -pe 's/ \n//g'
  | tee todoc.txt"
]

gulp.task "codo:serve", ["codo:build"], ->
  gulp.watch [
    p.src.coffee
    p.src.docs.styles
    p.src.docs.js
    p.src.docs.coffee
    p.src.docs.templates
  ], ["codo:build"]
