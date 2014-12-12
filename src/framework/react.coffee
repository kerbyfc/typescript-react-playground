global.React = require 'react/react'
global.Router = require 'react-router/dist/react-router'

for key, val of Router
  global[key] = Router[key]

module.exports = React
