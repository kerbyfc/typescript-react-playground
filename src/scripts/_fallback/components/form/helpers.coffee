"use strict"

_getContext = (context) ->
  if context then $ context else $ 'body'

exports.getEl = (selector, context) ->
  context = _getContext(context)
  if selector
    switch
      when _.isArray(selector)
        elems = $()
        for item in selector
          if elem = exports.getEl(item, context)
            elems.add elem
        elems

      else
        $ selector, context

exports.getElByName = (names, context) ->
  names = [names] unless _.isArray names

  selector = names
    .map (name) ->
      "[name='#{name}'],[name='#{name}[]']"
    .join ","

  exports.getEl selector, context, options = {}

###############################################################################
# Form-specified helpers (TODO: separate with above helpers in future)

exports.getFormEl = (selector, context, exclude) ->
  elems   = exports.getEl selector, context
  context = _getContext context

  for elem in elems
    for excepted in context.find(exclude or "form form").find(elem)
      elems = elems.not excepted

  elems

exports.getFormElByName = (names, context, exclude) ->
  exports.getFormEl exports.getElByName(names, context), context, exclude
