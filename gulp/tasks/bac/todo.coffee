todo     = require "gulp-todo"
tap      = require "gulp-tap"
replace  = require "gulp-replace"
merge    = require "gulp-merge"

gulp.task "todo:all", ->

  merge(
    src p.src.coffee
    src p.src.scss
    src p.src.components.templates
    )

    .pipe todo
      fileName: "todo.json"
      reporter: "json"

    .pipe tap (buffer) ->
      items = JSON.parse String buffer.contents
      unless _.isNull items

        tasks = _.map items, (item) ->
          new Promise (resolve, reject) ->

            ext = PATH.extname(item.file).slice 1

            base = switch ext
              when "scss"
                p.src.styles
              else
                p.src.scripts

            path = PATH.resolve base, item.file
            FS.readFile path, (err, data) ->
              if (err)
                throw err

              resolve _.extend item,
                content : String(data)
                ext     : ext

        Promise.all tasks
          .then (files) ->

            readme = src p.readme
            contents = ""

            for kind in ["TODO", "FIXME"]
              content = ""
              for f in _.where(files, kind: kind)

                if f.content
                  rows = f.content.split "\n"
                  content += "
                    ***#{f.file}***
                    \n#{f.text}\n```#{f.ext}
                    \n#{rows.slice(f.line - 3, f.line + 6).join("\n")}\n```\n\n"

              readme.pipe helpers.inject content, "### #{kind}s", "###"

            readme.pipe gulp.dest p.root

        buffer

