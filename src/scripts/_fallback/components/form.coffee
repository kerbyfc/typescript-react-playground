components =
  Input           : require "components/form/input.coffee"
  DateRangePicker : require "components/form/daterangepicker.coffee"

###*
 * Place to parametrize components
 *
 * @example
 *   factories =
 *     DateRangePicker: (element, context) ->
 *       switch $(element).data('type')
 *         when "bootstrap"
 *           new components.BootstrapDateRangePicker node, context
 *         # ...
 *
###
factories = {}

###*
 * Search component factory and run it or
 * just instantiate component if factory doesn't exist
 * @param {jQuery} element
 * @param {Object} context
 * @return {Marionette.Object} component instance
###
module.exports = (element, context) ->
  # kebab-case in templates (for convinient two-way name tranformations)
  name = _.capitalize _.camelCase $(element).data("formComponent")

  component = if factories[name]
    factories[name] element, context
  else
    new components[name] element, context

  component
