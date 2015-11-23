"use strict"

require "backbone.validation"
require "common/helpers.coffee"

# ## **App.Common.ValidationModel** используется для валидируемых моделей
# В этом классе кастомное переопределение методов `valid` `invalid`
class App.Common.ValidationModel extends Backbone.Model

_.extend App.Common.ValidationModel::, Backbone.Validation, Backbone.Validation.mixin

_.extend(
  App.Common.ValidationModel::callbacks,
  valid: (view, attr, selector) ->
    control = view.$("[#{selector}='#{attr}']").removeClass("error")

    if (control.data("error-style") is "tooltip")
      if (control.data("bs.popover"))
        return control.popover("hide")

    else if (control.data("error-style") is "inline")
      return control.find(".help-inline.error-message").remove()
    else
      return control.find(".help-block.error-message").remove()

  invalid: (view, attr, error, selector) ->
    control = view.$("[#{selector}='#{attr}']").addClass("error")

    if (control.data("error-style") is "tooltip")

      control.popover("destroy") if (control.data("bs.popover"))

      control.popover(
        html    : true
        placement : control.data("tooltip-position") or "right"
        trigger   : "manual"
        content   : error
        container : control.closest("[data-error-container]")
      ).popover("show")

    else if (control.data("error-style") is "inline")
      if (control.find(".help-inline").length is 0)
        control.find(".controls").append("<span class=\"help-inline error-message\"></span>")

      target = control.find(".help-inline")
      return target.text(error)
    else
      if (control.find(".help-block").length is 0)
        control.find(".controls").append("<p class=\"help-block error-message\"></p>")

      target = control.find(".help-block")
      return target.text(error)
)

_.extend App.Common.ValidationModel::patterns, App.Helpers.patterns

App.vent.once "session:start", ->
  _.extend App.Common.ValidationModel::messages, App.t('form.error', returnObjectTrees: true)

_.extend App.Common.ValidationModel::labelFormatters, locale: (attrName, model) ->
  type = App.entry.getConfig(model)?.type or model.type
  if type
    return App.t attrName, { postProcess: 'entry', entry: type }
  App.t "global.#{attrName}"

_.extend App.Common.ValidationModel::validators,
  format: ->
    key = arguments[0]
    App.t key,
      postProcess : 'sprintf'
      sprintf   : _.rest arguments

  formatLabel: (label, model) ->
    model.t label, context: 'label'

  not_unique_field: (value, attr, customValue, model) ->
    return if customValue is true
    App.t "form.error.not_unique_field"

  phone: (value, attr, customValue, model) ->
    allowed_length = @minLength value, attr, 3, model
    if allowed_length?
      return allowed_length

    unless value.match(
      ///
        ^
          (
            \d
            | -
            | _
            | \(
            | \)
            | \+
            | \x20
          )*
        $
      ///
    )?
      App.t 'form.error.invalid_phone'

  email: (value, attr, customValue, model) ->
    allowed_email = @pattern value, attr, "email", model
    if allowed_email?
      App.t 'form.error.invalid_email'

  ip: (value) ->
    unless value.match(
      ///
        \b
        (
          25[0-5]|2[0-4][0-9]
          |
          [01]?[0-9][0-9]?
        )
        \.
        (
          25[0-5]
          |
          2[0-4][0-9]
          |
          [01]?[0-9][0-9]?
        )
        \.
        (
          25[0-5]
          |
          2[0-4][0-9]
          |
          [01]?[0-9][0-9]?
        )
        \.
        (
          25[0-5]
          |
          2[0-4][0-9]
          |
          [01]?[0-9][0-9]?
        )
        \b
      ///
    )?
      App.t 'form.error.invalid_ip'

  dns: (value) ->
    unless value.match(
      ///
        ^
          (
            (
              [a-zA-Z0-9]
              |
              [a-zA-Z0-9][a-zA-Z0-9_\-]*
              [a-zA-Z0-9]
            )\.
          )
          *
          (
            [A-Za-z0-9]
            |
            [A-Za-z0-9][A-Za-z0-9_\-]*
            [A-Za-z0-9]
          )
        $
      ///
    )?
      App.t 'form.error.invalid_dns'

  less_then: (value, attr, customValue, model) ->
    if value > model.get(customValue)
      App.t 'form.error.less_then'

  more_then: (value, attr, customValue, model) ->
    if value < model.get(customValue)
      App.t 'form.error.more_then'

App.Common.ValidationModel::configure labelFormatter: 'locale'
