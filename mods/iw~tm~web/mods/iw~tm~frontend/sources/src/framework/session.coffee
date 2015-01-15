helpers = require 'helpers'

class Session

  established: false

  start: (callback) ->
    @check callback

  check: (cb) ->
    helpers.apiCall 'user/check'
      .error ->
        helpers.navigate '/signin', 'Sign in'
      .always =>
        cb?()

# singleton
module.exports = new Session
