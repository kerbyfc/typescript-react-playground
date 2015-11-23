"use strict"

select2 = require "common/select2.coffee"
require "backbone.syphon"

Backbone.Syphon.InputWriters.register "checkbox", ($el, value) ->
  if value is undefined then return

  value = switch value
    when 'false', '0'
      false
    else
      # true, '1', 'true' etc -> true
      # false, '', null etc -> false
      Boolean value

  $el.prop 'checked', value

Backbone.Syphon.InputWriters.register "select", ($el, value) ->
  value = "" if value is null
  $el.val value if value?

Backbone.Syphon.InputReaders.register "select", ($el, value) ->
  val = $el.val()
  if val is "" then null else val

Backbone.Syphon.InputReaders.register "checkbox", ($el) ->
  checked = $el.prop("checked")
  return if checked then 1 else 0

Backbone.Syphon.InputWriters.register "radio", ($el, value) ->
  if value isnt null
    $el.prop("checked", $el.val() is value or parseInt($el.val()) is value)

Backbone.Syphon.InputWriters.register "textarea", ($el, value) ->
  if $el.data('form-type') is 'select2' and value
    value = _.map value, (item) -> "#{item.TYPE}#{select2.innerSeparator}#{item.ID}#{select2.innerSeparator}#{item.NAME}"
    value = value.join select2.outerSeparator

  $el.val value


Backbone.Syphon.InputWriters.register "text", ($el, value) ->
  if $el.data('form-type') is 'time'
    value = "00:00" unless value

  $el.val value
