Api = require "core/api/base"

class Api.V1 extends Api

  api: App.config.api[App.config.api.version]

module.exports = new Api.V1
