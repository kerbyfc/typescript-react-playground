# This addStepDefinitions() function is why the step definitions must
# be configured to load after the adapter.
addStepDefinitions (feature) ->

  # Provide a custom World constructor. It's optional, a default one is supplied.
  feature.World = (callback) ->
    callback()

  # Define your World, here is where you can add some custom utlity functions you
  # want to use with your Cucumber step definitions, this is usually moved out
  # to its own file that you include in your Karma config
  proto = feature.World::
  proto.appSpecificUtilityFunction = someHelperFunc = ->

  # do some common stuff with your app

  # Before feature hoooks
  feature.Before (callback) ->

    # Use a custom utility function
    @appSpecificUtilityFunction()
    callback()

  feature.Given /^some predetermined state$/, (callback) ->

    # Verify or set up an app state

    # Move to next step
    callback()

  feature.When /^the user takes an action$/, (callback) ->

    # Trigger some user action

    # Move to next step
    callback()

  feature.Then /^the app does something$/, (callback) ->

    # Verify the expected outcome

    # Move to next step
    callback()


  # After feature hooks
  feature.After (callback) ->
    callback()

