(
  (root, factory) ->

    if typeof define is 'function' and define.amd
      # AMD. Register as an anonymous module.
      define [], factory
    else if typeof exports is 'object'
      # Node. Does not work with strict CommonJS, but
      # only CommonJS-like environments that support module.exports,
      # like Node.
      module.exports = factory()
    else
      # Browser globals (root is window)
      root.Blender = factory()

) @, ->

  class Blender

    ###*
     * Blender instancies
     * @type { Array }
    ###
    states = []

    ###*
     * Instance counter
     * @type { Number }
    ###
    couter = 0

    ###*
     * Rule types dict represents
     * state consistency decision modifier
     * @type { Object }
    ###
    ruleTypes:
      consistent: true
      inconsistent: false

    ###*
     * Methods that should be used as proxy
     * @type { Array }
    ###
    interface: [
      "blend"
      "isConsistent"
      "isntConsistent"
    ]

    ###*
     * Setup blender instance
     * @param { Object } options
    ###
    constructor: (options) ->
      @rules = {}
      @data  = {}

      # copy options object
      # FIXME remove lodash dependency
      options = _.extend {}, options

      @_instance = couter++

      states[@_instance] = {}

      for ruleType in Object.keys @ruleTypes
        # default
        @rules[ruleType] = []

        # check passed config
        if typeof options[ruleType] is "object"
          @rules[ruleType] = Array.prototype.map.call options[ruleType], (rule) ->
            unless rule instanceof RegExp
              return new RegExp rule
            rule

          # cut rules
          delete options[ruleType]

      # all other properties represents state
      @options = options

    ###*
     * @example
     *     if state.set({...}).consistent
     *       model.set state.get()
     *
     * @param { Object } data - new data for state
     * @param { Object } options = force: false
    ###
    set: (data, options = force: false) ->
      mix = @blend data

      # do not change state for safe mode
      unless options.force or mix.consistent
        return mix

      states[@_instance] = mix
      mix

    ###*
     * Get copy of state
     * @param  { String } key
     * @return { Any  } data
    ###
    get: (key) ->
      state = {}
      state[key] = val for key, val of states[@_instance]

      unless key
        state.data
      else
        state.data[key]

    ###*
     * Blend new mix and check it's consistence
     * @param  { Object } data ingredients
     * @return { Object } state
    ###
    blend: (data) ->

      state =
        consistent    : false
        data      : data
        inconsistency : []

      positive = true

      inconsistency = state.inconsistency

      for type, mod of @ruleTypes

        for rule in @rules[type]

          # accumulate matching data
          report =
            options : []
            values  : []
            summary : {}
            type  : type
            rule  : rule.toString()

          # search matches for each data value
          for key, value of state.data
            if rule.test value
              report.options.push key
              report.values.push value
              report.summary[key] = value

          # if there are few options matched
          # state becomes inconsistent for proper matching type
          found = report.values.length > 1

          # by default state is consistent,
          # positive rules are the first and if
          # such rule was mached, we mark
          # state as consistent and break
          # positive rules mathing cycle
          if mod is positive

            if found
              state.consistent = true
              # break positive rules mathing cycle
              break

          else
            # negative matches are after positive
            if found
              inconsistency.push report
              state.consistent = false

      unless state.inconsistency.length
        delete state.inconsistency

      state

    ###*
     * Determine if data is consistent
     * @param  { Object  } data ingredients
     * @return { Boolean } consistent decision
    ###
    isConsistent: (data = @get().data) ->
      @blend data
        .consistent

    ###*
     * Determine if data is NOT consistent
     * @param  { Object  } data ingredients
     * @return { Boolean } consistent decision
    ###
    isntConsistent: (data = @get().data) ->
      not @blend data
        .consistent

    ###*
     * Create proxy methods for target object
     * @param  { Object } target
     * @return { Object } target with blender methods
    ###
    bridge: (target) ->
      for method in @interface
        do (method) =>
          unless target[method]
            target[method] = =>
              @[method] arguments...
      target
