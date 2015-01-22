YAML = require 'yamljs'
cfg = YAML.load "config.yml"
module.exports = (config) ->

  console.log "HERE"
  # console.log JSON.stringify cfg, null, 2

  config.set

    basePath: ''
    colors: true

    files: [
      {
        pattern: 'node_modules/karma-cucumberjs/vendor/cucumber-html.css'
        watched: false
        included: false
        served: true
      }
      {
        pattern: cfg.paths.index_file
        watched: false
        included: false
        served: true
      }
      {
        pattern: cfg.cucumber.paths.features
        watched: true
        included: false
        served: true
      }
      {
        pattern: cfg.cucumber.paths.definitions
        watched: true
        included: true
        served: true
      }
    ]

    frameworks: [
      'cucumberjs'
    ]

    preprocessors:
      '**/*.coffee': 'coffee'

    browsers: [
     'Chrome'
    ]
