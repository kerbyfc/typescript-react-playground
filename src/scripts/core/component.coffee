###*
 * Base component class, the prototype of all
 * project components.
 *
 * @example Component creation
 *   class Dropdown extends Component
 *     locals: ->
 *       msg: "hello"
 *
 * @example Component instantiation
 *   Dropdown = require "dropdown"
 *   Dropdown
 *
 *     # Properties
 *     text: "my button"
 *     onClick: ->
 *       alert("click")
 *
 *     # Children
 *     [
 *       Link to: "users"   # children also may be passed
 *       Link to: "events"  # via properties with `children` key.
 *     ]                    # If children were passed in 3-rd param -
 *                          # props.children will be ignored
 *
 * @see ../extra/README.md.html#toc_10 Components scaffolding
 * @author Lukin A.
###
class Component

  ###*
   * Backup of an origianl React.createElement.
   *
   * @private
   * @type {Function}
  ###
  _ce = React.createElement

  ###*
   * Cache to store react components specs.
   *
   * @private
   * @type {Object}
  ###
  _specs = {}

  ###*
   * Translate component class to React class.
   *
   * @param  {Component} comopnent * any Component-based class
   *
   * @return {Object} spec for React class
  ###
  @reactify = (component) ->
    component = _specs[component.name] ?= React.createClass(
      _(new component)
        .extend cName: component.name
        .omit 'constructor'
        .value()
    )
    component

  ###*
   * Create react component.
   *
   * @note Remove undefined/null children
   *   from children list for convenience! (useful with `if` statements)
   *
   * @param  { Component     } component     * component class / react class
   * @param  { Object        } props         * properties
   * @param  { Array         } childred      * array of children components
   *
   * @return { React.Element } react element
  ###
  @create = (component, props, children = props?.children) ->

    if _.isArray children
      children = _.compact children

    # not a react component, tranform
    if component and component._isComponentClass?
      component = Component.reactify component

    _ce component, props, children

  React.createElement = @create

  ###*
   * Initialize default properties.
   *
   * @note Process *greedy inheritance*.
   * @note all objects (except functions) should be copied via _.clone
   * @todo think about copying objects
   *
   * @param  {Array} args... * for Component.create (with `new`)
   *
   * @return {Component|Object} component without `new`, Object otherwise
  ###
  constructor: (args...) ->
    if @ instanceof Component
      # component spec creation
      if @__super__?
        for key, val of super
          if _.isFunction val
            @[key] ?= ->
              super[key] arguments...

          # TODO think about it
          else if _.isObject val
            @[key] = _.clone super[key]
    else
      # component instantiation
      React.createElement @, args...

  # to detect components
  @_isComponentClass = true

  ###*
   * Cascade method for getDefaultProps.
   * Place here the code to define component
   * initial props.
   *
   * @abstract Might be implemented
   * @see Component#getDefaultProps
   * @return {Object} default properties
  ###
  defaultProps: ->
    {}

  ###*
   * Call defaultProps method.
   * if it's a function, otherwise return it.
   *
   * @private
   * @note executes in another scope,
   *   rather than component scope
   * @see http://facebook.github.io/react/docs/component-specs.html#getdefaultprops
   *   method official spec
   * @todo doc params
   *
   * @return {Object} properties object
  ###
  getDefaultProps: ->
    if _.isFunction @::defaultProps
      # executes in another scope
      @::defaultProps()
    else
      @::defaultProps

  ###*
   * Cascade method for getInitialState.
   * Form an initial state object.
   *
   * @abstract Might be implemented might be implemented
   * @see Component#getInitialState
   * @todo doc params
   *
   * @return {Object} default properties
  ###
  initState: (props) ->
    nextProps

  ###*
   * Calls initState method.
   *
   * @private
   * @see Component#initState
   * @see http://facebook.github.io/react/docs/component-specs.html#getinitialstate
   *   method official spec
   * @todo add link to antipatterns
   *
   * @return {Object} state object
  ###
  getInitialState: ->
    @initState arguments...

  ###*
   * Cascade method for componentWillReceiveProps.
   * Place here the code manipulations when component
   * receive properties from it's parent component.
   *
   * @abstract Might be implemented
   * @see Component#componentWillReceiveProps
   * @todo doc params
   *
  ###
  updateProps: -> null

  ###*
   * Calls updateProps.
   *
   * @private
   * @todo add @see to of-doc
   * @see Component#updateProps
  ###
  componentWillReceiveProps: (nextProps) ->
    @updateProps arguments...

  ###*
   * Calls beforeMount.
   *
   * @todo add @see to of-doc
   * @see Component#beforeMount
   * @private
  ###
  componentWillMount: ->
    @beforeMount arguments...

  ###*
   * Cascade method for componentWillMount.
   * Invoked once, immediately before the initial rendering occurs.
   * If you call setState within this method, *render()* will see
   * the updated state and will be
   * executed only once despite the state change.
   *
   * @abstract Might be implemented
   * @see Component#componentWillMount
   * @todo doc params
  ###
  beforeMount: ->
    null

  ###*
   * Calls onMount
   *
   * @see Component#onMount
   * @private
   * @todo add @see to of-doc
  ###
  componentDidMount: ->
    @onMount arguments...

  ###*
   * Cascade method for componentDidMount.
   *
   * @abstract Might be implemented
   * @todo  doc params
   * @see Component#componentWillMount
   * @return {[type]} [description]
  ###
  onMount: ->
    null

  ###*
   * Calls willUpdate
   *
   * @see Component#willUpdate
   * @return {[type]}           [description]
  ###
  shouldComponentUpdate: ->
    @willUpdate arguments...

  ###*
   * Place here the code to permit updates.
   *
   * @todo  doc params
   *
   * @abstract Might be implemented
   * @param  {Object} nextProps * next properties
   * @param  {Object} nextState * next state
   *
   * @return {Boolean} update decision
  ###
  willUpdate: (nextProps, nextState) ->
    true

  ###*
   * Calls willUpldate
   *
   * @see Component#willUpdate
   * @private
   * @todo  add @see to of-doc
  ###
  componentWillUpdate: ->
    @beforeUpdate arguments...

  ###*
   * Cascade method for componentWillUpdate.
   * Place here the code to resolve component state.
   *
   * @abstract Might be implemented
   * @todo params doc
   * @see Component#componentWillUpdate
  ###
  beforeUpdate: ->
    null

  ###*
   * Calls onUpdate method.
   *
   * @todo see to of-doc
   * @see  Component#onUpdate
   * @private
   *
  ###
  componentDidUpdate: ->
    @onUpdate arguments...

  ###*
   * Cascade method for componentWillUpdate.
   *
   * @abstract Might be implemented
   * @todo  params doc
   * @see Component#componentWillUpdate
  ###
  onUpdate: ->
    null

  ###*
   * Calls onUnmount
   *
   * @see Component#onUnmount
   * @private
   * @todo add @see to of-doc
  ###
  componentWillUnmount: ->
    @onUnmount arguments...

  ###*
   * Cascade method for componentWillUnmount.
   *
   * @abstract Might be implemented
   * @todo  doc params
   * @see Component#componentWillUnmount
  ###
  onUnmount: ->
    null

  ###*
   * Renders template. Template by default
   * must be set to template property of component
   *
   * @note Components scafolding setups components
   *  template property automaticaly.
   *
   * @see ../extra/README.md.html#toc_10 Components scaffolding
   *
   * @return {React.DOM} virtual dom
  ###
  render: ->
    @template? _.extend {}, @, @locals()

  ###*
   * Resolves locals for template
   * @abstract Might be implemented
   *
   * @return {Object} locals
  ###
  locals: ->
    {}

  ###*
   * Get component el
   *
   * @return {Object} dome node
  ###
  el: ->
    @getDOMNode()

  ###*
   * Get jQuery-wrapped component el
   * @example
   *   alert @$el()[0] is @el() # true
   *
   * @return {jQuery} jquery object
  ###
  $el: ->
    $ @el()

  ###*
   * Find nodes inside component node by $.fn.find
   * Aka backbonde.
   *
   * @example
   *   @$ "input#username"
   *     .val()
   *
   * @param  {String} selector * query selector
   *
   * @return {jQuery} jquery object
  ###
  $: (selector) ->
    @$el().find selector

  ###*
   * Determine if the given node is inside
   * another node
   *
   * @example
   *   handleClick: (e) ->
   *     unless @isNodeInRoot e.target, @el()
   *       alert "close dropdown"
   *
   * @param  {Object} node * target dom node
   * @param  {Object} root * dom node to search in
   *
   * @return {Boolean} search result
  ###
  isNodeInRoot: (node, root) ->
    while node
      if node is root
        return true
      node = node.parentNode
    return false

  ###*
   * Checks if component contains node. Returns jQuery object if
   * component includes element, false otherwise.
   *
   * @param  {HTMLElement|jQuery} node * dom node or jquery object
   *
   * @return {Boolean|jQuery} false or jquery object
  ###
  contains: (node) ->
    el = $ node
      .closest @$el()
    el.length and el or
      false

module.exports = Component
