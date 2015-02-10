plumber = require "gulp-plumber"
replace = require "gulp-replace"

module.exports =

  fullpath: (_path, cwd = process.cwd()) ->
    if _.isArray _path
      return ( for entry in _path
        helpers.fullpath entry, cwd )
    PATH.resolve cwd, _path

  glob: (paths) ->
    _paths = for _path in _.clone(paths)
      if _.contains _path, "*"
        GLOB.sync _path
      else
        _path
    _.flatten _paths

  # form ComponentName based on directory_name
  compName: (dirname) ->
    dirname.split "_"
      .map (chunk) ->
        _.capitalize chunk
      .join ""

  inject: (content, start, end) ->
    replace(
      ///(#{start})((?!#{end}).|\n)+///g
      "$1\n#{content}$2\n"
    )

  className: (dirname) ->
    dirname.replace(/\_/g, '-') + cfg.component.classNameSuffix
