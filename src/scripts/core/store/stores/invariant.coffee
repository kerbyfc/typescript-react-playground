###*
# Use invariant() to assert state which your program assumes to be true.
#
# Provide sprintf-style format (only %s is supported) and arguments
# to provide information about what broke and what you were
# expecting.
#
# The invariant message will be stripped in production, but the invariant
# will remain to ensure logic does not differ in production.
###

invariant = (condition, format, args...) ->
  if !condition
    error = undefined
    if format == undefined
      error = new Error('Minified exception occurred; use the non-minified dev environment ' + 'for the full error message and additional helpful warnings.')
    else
      argIndex = 0
      error = new Error('Invariant Violation: ' + format.replace(/%s/g, ->
        args[argIndex++]
      ))
    error.framesToPop = 1
    # we don't care about invariant's own frame
    throw error
  return

module.exports = invariant
