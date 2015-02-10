tap    = require "gulp-tap"
yaml   = require "gulp-yaml"
wrap   = require "gulp-wrap"
concat = require "gulp-concat"
rename = require "gulp-rename"

# transform .yml files
# to .json fils
gulp.task "yaml:build", ->
  src p.src.yaml
    .pipe yaml
      space: 2

    # if file stream has `shared":` substring
    # try to parse json and pick only shared objects
    .pipe tap (buf) ->
      c = buf.contents.toString()
      if c.match /shared"[\s]*\:/
        try
          c = JSON.parse c
          # pick only
          buf.contents = new Buffer(
            JSON.stringify(
              _.pick(c, c.shared)
              null, 2
            )
          )
      buf.contents = buf.contents.slice 1, buf.contents.length - 1
      buf

    .pipe concat("config", newLine: ",")
    .pipe wrap("{<%= contents %>}")
    .pipe rename("config.json")
    .pipe save()

gulp.task "yaml:serve", ["yaml:build"], ->
  gulp.watch p.src.yaml, ["scripts:build"]
