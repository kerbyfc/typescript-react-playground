"use strict"


###*
 * Finds and parses JSON strings in JSON received from the server
###
class App.Common.TextParamParser extends Backbone.Model

  parse: (data) ->
    @_parseObject super(data)

  ##############################################################################
  # PRIVATE

  ###*
   * Splits received JSON data into properties and sends each to parser
   * Then saves result to the string
   * @param {Object} object - incoming data
   * @return {Object} parsed data
  ###
  _parseObject: (object) ->
    for own key, val of object
      object[key] = @_parseJSONParam val

    object

  ###*
   * Detects if property is a JSON string, if one is - parses it
   * Further if result is object sends it to a further parse
   * @param {Object|String} val - incoming property
   * @return {String} resulting lowest-level string property
  ###
  _parseJSONParam: (val) ->
    try
      @_parseObject JSON.parse val

    catch error
      if _.isObject val
        @_parseObject val

      else
        val


###*
 * Formats data property structure
 *
 * Incoming property structure
 * _nestedStart:
 *   _nestedAggr: [
 *     _nestedKey: key
 *     _nestedValue:
 *       value or _nestedAggr: ...
 *   ]
 *
 * Resulting property structure
 * String
 * OR
 * Array of strings
 * OR
 * [{NAME, TYPE, COLOR}]
###
class App.Common.NestedModelParser extends App.Common.TextParamParser

  PROP_TYPE  : "TYPE"
  PROP_NAME  : "NAME"
  PROP_COLOR : "COLOR"

  parse: (data) ->
    super data

    @_parseNested data

  ##############################################################################
  # PRIVATE

  _nestedStart : "data"
  _nestedAggr  : "children"
  _nestedKey   : "category"
  _nestedValue : "value"

  _otherNameVals: [
    'DISPLAY_NAME'
  ]

  ###*
   * Checks object recursively for the nested params
   * @param {Object} object - Incoming data
   * @return {Object} Resulting data
  ###
  _parseNested: (object) ->
    for own key, val of object
      if key in @_otherNameVals
        object[@PROP_NAME] = val

      if _.isString val
        @_formatString val

      if _.isObject val

        # Looks for the attribute with the nested structure in it
        # Ex. VISIBILITY_AREA_ID: @@_nestedStart: ...
        if val.hasOwnProperty @_nestedStart
          children = val[@_nestedStart][@_nestedAggr]
          @_flattenNested object, children

          # Deletes the attribute with nested structure
          delete object[key]

        else
          object[key] = @_parseNested val

    object

  ###*
   * Moves all nested attributes on the upmost level recursively
   * @param {Object} object - Upmost level, is kept through recursion
   * @param {Object} children - Parsed objects, starters are upmost's children
   * @return {Object} Resulting data
  ###
  _flattenNested: (object, children) ->

    for child in children
      if child.hasOwnProperty @_nestedAggr
        @_flattenNested object, child[@_nestedAggr]

      else
        key = child[@_nestedKey]
        object[key] = @_parseChild child[@_nestedValue]

  ###*
   * Finds elements with structure {name, type, value: []}
   * And converts them to [{NAME, TYPE}] structure
   * @param {Object} childValue - {name, type, value: []} structure
   * @return {Object} {NAME, TYPE} structure
  ###
  _parseChild: (childValue) =>

    _nestedArray      = "value"
    _nestedArrayType = "type"

    res = {}

    if _.isPlainObject childValue

      # If structure is {name, type, value: []}
      if childValue.hasOwnProperty _nestedArray
        return childValue[_nestedArray].map (name) =>
          res[@PROP_TYPE] = childValue[_nestedArrayType] ? null
          res[@PROP_NAME] = name
          [res]

    if _.isArray childValue
      return childValue.map @_parseChild

    if _.isString childValue
      return @_formatString childValue

    childValue

  ###*
   * Formats strings to object
   * @param {String} string - Incoming string
   * @return {Object} Output format
  ###
  _formatString: (string) ->
    res = {}
    res[@PROP_NAME] = string
    res
