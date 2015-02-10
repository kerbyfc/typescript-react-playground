api =
  v1: require "core/api/v1"

module.exports = api[App.config.api.version]
