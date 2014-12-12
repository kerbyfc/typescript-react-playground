# backup origin function
_ce = React.createElement

# cache to store react components
_cache = {}

# create component class to take it's
# spec or get it from cache if it has
# been already done, do some magic and
# call origin React.craeteElement
#
# @todo fix docs
#
# @param type     [ Class  ] component class
# @param props    [ Object ] component properties
# @param children [ Array  ] childrens
# @return         [ React  ] component instance
#
React.createElement = (type, props, children) ->
  if type._isComponentClass?
    component = _cache[type.name] ?= React.createClass _.omit new type, 'constructor'
    _ce component, props, children
  else
    _ce arguments...

class Component

  @_isComponentClass = true

  scheme: (options = {}) ->
    {}

  initProps: ->
    {}

  # Initialize default properties,
  # make type conversions
  #
  # @return [Component] instance
  #
  constructor: ->
    if @__super__?
      for key, val of super
        @[key] ?= ->
          super[key] arguments...

  # bridge to React getInitialState
  #
  # @param props [ Object ] description
  # @return      [ Object ] state object
  #
  getInitialState: (props) ->
    @initState arguments...

  initState: -> {}

  #
  # -> React's componentWillReceiveProps
  #
  # @param nextProps [Object] new properties
  #
  componentWillReceiveProps: (nextProps) ->
    @updateProps arguments...

  updateProps: -> null

  # -> React's componentWillMount
  #
  componentWillMount: ->
    @beforeMount arguments...

  beforeMount: -> null

  # -> React's componentDidMount
  #
  componentDidMount: ->
    @onMount arguments...

  onMount: -> null

  # -> React's shouldComponentUpdate
  #
  # @param nextProps [ Object  ] new props
  # @param nextState [ Object  ] new state
  # @return          [ Boolean ] update decision
  #
  shouldComponentUpdate: (nextProps, nextState) ->
    @updateIf arguments...

  updateIf: -> true

  # -> React's componentWillUpdate
  #
  # @param nextProps [Object] new props
  # @param nextState [Object] new state
  #
  componentWillUpdate: (nextProps, nextState) ->
    @beforeUpdate arguments...

  beforeUpdate: -> null

  # -> React's componentDidUpdate
  #
  # @param prevProps [Object] prev props
  # @param prevState [Object] prev state
  #
  componentDidUpdate: ->
    @onUpdate arguments...

  onUpdate: -> null

module.exports = Component
