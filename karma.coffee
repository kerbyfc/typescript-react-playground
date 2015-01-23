YAML = require "yamljs"
_    = require "lodash"

module.exports = (config) ->

  cfg = YAML.load "config.yml"

  config.set

    cgf: cfg

    basePath: ""
    colors: true

    customLaunchers:
      Chrome_without_security:
        base: "Chrome",
        flags: [
          "--disable-web-security"
          "--ignore-certificate-errors"
          "--no-sandbox"
          "--disable-hang-monitor"
          "--start-maximazed"
        ]

    files: _.values
      bootstrap:
        pattern: cfg.paths.bootstrap
        watched: true
        included: true
        served: true
      features:
        pattern: cfg.cucumber.paths.features
        watched: true
        included: false
        served: true
      step_definitions:
        pattern: cfg.cucumber.paths.definitions
        watched: true
        included: true
        served: true

    frameworks: [
      "cucumberjs"
    ]

    preprocessors:
      "**/*.coffee": "coffee"

    browsers: [
     "Chrome_without_security"
    ]
