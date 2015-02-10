class Api

  ###
  * Join url
  * @param  {String}  chunks... some
  * @return {String}            ret
  ###
  urlPath: (chunks...) ->
    chunks = for chunk in chunks
      chunk.replace /(^[\s]*\/)|(\/[\s]*$)/g, ''
    chunks.join '/'

  api: config.api[config.api_version]


module.exports = Api
