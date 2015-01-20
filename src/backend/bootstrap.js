/*
 * Copyright 2011-2012 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// var vertx = require('vertx')
// var console = require('vertx/console')
// var cookies = "";

// var client = vertx.createHttpClient().host('tm6.infowatch.ru').port(443).ssl(true).trustAll(true);

// req = client.post('/api/login', function(resp) {
//   console.log("Got response " + resp.statusCode());
//   console.log("Cookies " + resp.cookies());
//   cookies = resp.cookies();
//   resp.bodyHandler(function(body) {
//     console.log("Got data " + body);


//     req = client.get('/api/user/check', function(resp){
//       console.log("-----------------------------------------")
//       console.log("Got response " + resp.statusCode());
//       resp.bodyHandler(function(body) {
//         console.log("Got data " + body);
//       })
//     });

//     req.putHeader('Cookie', cookies).end()

//   })
// });

// data = {username: "officer", password: "xx1234"}
// size = JSON.stringify(data).length
// req.putHeader('Content-Length', size).write(JSON.stringify(data)).end()

var container = require('vertx/container');
var console = require('vertx/console');

console.log("SOME")

container.deployVerticle('user.js', {}, function(err, id) {
  if (err) {
    console.log(err);
  }
});
