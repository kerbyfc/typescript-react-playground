rename   = require "gulp-rename"
template = require "gulp-template"

# get gulp arguments
argv = require "yargs"
  .argv

gulp.task "scaffold", ->
  target = switch true
    when argv.c?
      "component"
    else
      false
  if target
    gulp.start "scaffold:#{target}"

gulp.task "scaffold:component", ->

  component = helpers.fullpath PATH.join [

      # resolve module directory path when -m was passed
      (argv.m and
        PATH.join p.src.modules, argv.m) or # - in module or ...
          p.src.scripts # - ... in base

      # relative components dir path
      cfg.paths.common.components
      # component name
      argv.c
    ]...
  dir = PATH.dirname component

  # check components directory existance
  fs.exists dir, (exists) ->
    unless exists
      return console.log "Can't find #{dir}"

    # check if component already exists
    fs.exists component, (ok) ->
      if ok
        if argv.f?
          fs.removeSync component
        else
          return console.log "Component already exists. User -f to override"

      # generate
      fs.mkdir component, (err) ->
        throw err if err

        # basename must be in lower case (convention)
        basename = PATH.basename component
          .toLowerCase()

        deps = argv.d?
        if deps

          # check dependencynot
          unless _.isString argv.d or argv.d isnt ""
            return console.log "Dependency list is empty"

          deps = argv.d.split(',')
          # transform [btn,link] to {Btn:btn,Link:link}
          deps = _.object _.map(_.clone(deps), helpers.componentName), deps

        # use all component templates, defined in config
        for tpl in cfg.scaffold.component
          src tpl
            .pipe template
              component : helpers.componentName(basename)
              classname : helpers.cssClassName(basename)
              filename  : basename
              complete  : argv.complete?
              deps      : deps
            .pipe rename
              basename: basename
            .pipe gulp.dest component
