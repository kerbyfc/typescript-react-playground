cssimport = require "gulp-cssimport"
scss      = require "gulp-sass"
replace   = require "gulp-replace"

gulp.task "scss:inject", ->

  paths = _.map (GLOB.sync p.src.components.styles), (p) ->
    name = PATH.basename p, ".scss"
    "@import '#{PATH.join name, name}.scss';"

  src p.src.style
    .pipe helpers.inject paths.join("\n"), "// COMPONENTS", "$"
    .pipe save p.src.styles

# compile scss
gulp.task "scss:build", ["scss:inject"], ->
  src p.src.style
    .pipe scss
      includePaths: helpers.glob helpers.fullpath cfg.scss.includePaths
    .pipe replace /\((.*)(\.css)\)/g, "(/../bower_components/$1$2)"
    .pipe cssimport()
    .pipe save()

gulp.task "scss:serve", ["scss:build"], ->
  gulp.watch p.src.scss, ["scss:build"]
