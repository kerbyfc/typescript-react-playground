vertx = require 'vertx'

eb           = vertx.eventBus
server       = vertx.createHttpServer()
routeMatcher = new vertx.RouteMatcher()

server.requestHandler (req) ->
  if req.path().match /\.js$/
    req.response.sendFile 'sources/build/' + req.path()
  else
    req.response.sendFile 'sources/build/index.html'

server.listen(8080, 'localhost');
