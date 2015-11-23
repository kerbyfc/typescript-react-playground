config = require("config.json")

api = {
  v1: require("api/v1")
}

module.exports = new api[config.api.version]
