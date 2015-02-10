karma = require "karma"

gulp.task "karma", (done) ->
  karma.server.start
      configFile: helpers.fullpath p.karma
    , done
