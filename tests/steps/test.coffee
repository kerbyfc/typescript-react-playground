# features/step_definitions/myStepDefinitions.js
module.exports = ->
  @World = (done) ->
    done
      date: null
      test: ->
        console.log "HERE"

  @Given /^я ничего не делал$/, (done) ->
    done()

  @When /^мне нужно перевести дату (\d+) в UTF$/, (date, done) ->
    @date = parseInt date
    done()

  @Then /^я увижу "([^"]*)"$/, (utcDate, done) ->
    if utcDate is "Thu, 22 Jan 2015 08:53:45 GMT"
      @test()
      done()
    else
      done.fail new Error "Date is invalid"
