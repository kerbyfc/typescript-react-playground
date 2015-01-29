React = require 'react'
require 'store'

# backup origin function
_ce = React.createElement

# cache to store react components
_cache = {}

createReactComponent = (type) ->
  React.createClass _.extend cName: type.name,
    _.omit new type, 'constructor'

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

  # HACK for convenience!
  # remove undefined children
  if _.isArray children
    children = _.compact children

  switch true
    when type and type._isComponentClass?
      component = _cache[type.name] ?= createReactComponent type
      _ce component, props, children
    when _.isFunction type
      cName = type.type.prototype.cName = type.displayName
      _ce arguments...
    else
      _ce arguments...

# Base component class
# @example subclassing
#   class ButtonComponent extends Component
#
module.exports = class Component

  # флаг компонента, необходим
  # для определения того, есть ли в
  # цепочке прототипов класса класс Component
  #
  # @note используется в переопределенном
  #   методе React.createElement
  #
  @_isComponentClass = true

  # get default props
  #
  # @return [Object] props object
  #
  defaultProps: ->
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
  getInitialState: ->
    @initState arguments...

  # state initializer
  #
  # @param nextProps [ Object ] description
  # @return          [ Object ] state object
  #
  initState: (nextProps = {}) ->
    nextProps

  #
  # React's componentWillReceiveProps
  #
  # @param nextProps [Object] new properties
  #
  componentWillReceiveProps: (nextProps) ->
    @updateProps arguments...

  # update props method noop
  # @todo add method description
  #
  # @return [Null]
  #
  updateProps: -> null

  # React's componentWillMount
  #
  # @return [void] this.beforeMount results
  #
  componentWillMount: ->
    @beforeMount arguments...

  # beforeMount method noop
  # @todo add method description
  #
  # @return [Null]
  #
  beforeMount: -> null

  #
  # React's componentDidMount
  #
  # @private
  # @see Component#onMount
  # @return [void]
  #
  componentDidMount: ->
    @onMount arguments...

  # beforeMount method noop
  # @todo add method description
  #
  # @return [Null]
  #
  onMount: -> null

  # React's shouldComponentUpdate
  #
  # @param nextProps [ Object  ] new props
  # @param nextState [ Object  ] new state
  # @return          [ void    ] this.updateIf results
  #



  # Should component update method
  # @param  [Object] nextProps
  # @param  [Object] nextState
  # @return [Boolean] should update decision
  #
  shouldComponentUpdate: (nextProps, nextState) ->
    @updateIf arguments...

  # updateIf method noop
  # @todo add method description
  #
  # @return [Null]
  #
  updateIf: -> true

  # -> React's componentWillUpdate
  #
  # @param nextProps [Object] new props
  # @param nextState [Object] new state
  #
  componentWillUpdate: (nextProps, nextState) ->
    @beforeUpdate arguments...

  # actions before update
  #
  beforeUpdate: -> null

  # -> React's componentDidUpdate
  #
  # @param prevProps [Object] prev props
  # @param prevState [Object] prev state
  #
  componentDidUpdate: ->
    @onUpdate arguments...

  # actions after update
  #
  onUpdate: -> null

  # Get name of the parent component (owner)
  # Skip RouteHandler components
  # @param  [Compoment] current component
  # @return [String]    component name
  #
  getParentName: (cur = @) ->
    while owner = cur._owner
      name = owner.cName
      return name unless name is "RouteHandler"
      cur = owner
