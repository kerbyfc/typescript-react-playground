###*
 * Base component class, the prototype of all
 * project components.
 *
 * @example Component declaring
 *   class Dropdown extends App.Component
 *     template: App.JSX.dropdown
 *     locals: ->
 *       msg: "hello"
 *
 * @example Component usage
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
    _specs[component.name] ?= React.createClass(
      _(new component)
        .extend cName: component.name
        .omit 'constructor'
        .value()
    )

  ###*
   * Create react component.
   *
   * @note Remove undefined/null children
   *   from children list for convenience! (useful with `if` statements
   *   in array of children)
   *
   * @param  {Component} component * component class / react class
   * @param  {Object} props * properties
   * @param  {Array} childred * array of children components
   *
   * @return {React.Element} react element
  ###
  @create = (type, props, children = props?.children) ->

    if _.isArray children
      children = _.compact children

    switch true
      # coffee script class component
      when type and type._isComponentClass?
        _ce Component.reactify(type), props, children

      # react complex component
      when _.isFunction type
        cName = type.type.prototype.cName = type.displayName
        _ce arguments...

      else
        # simple dom component
        _ce arguments...

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

          # TODO
          else if _.isObject val
            @[key] = _.clone super[key]
    else
      # component instantiation
      React.createElement @, args...

  # to detect components
  @_isComponentClass = true

  ###*
   * Cascade method for getDefaultProps. Place here the
   * code to define component initial props.
   * Invoked once and cached when the class is created. Values
   * in the mapping will be set on this.props if that
   * prop is not specified by the parent component
   * (i.e. using an in check). This method is invoked before
   * any instances are created and thus cannot rely on this.props.
   * In addition, be aware that any complex objects returned
   * by getDefaultProps() will be shared across instances, not copied.
   *
   * @abstract Might be implemented
   * @see Component#getDefaultProps
   *
   * @return {Object} default properties
  ###
  defaultProps: ->
    {}

  ###*
   * Call defaultProps method, if it's a function,
   * otherwise return it.
   *
   * @private
   * @abstract Shouldn't be implemented.
   * @note executes in another scope,
   *   rather than component scope. LifeCycle order: 1
   * @see http://facebook.github.io/react/docs/component-specs.html#getdefaultprops
   *   method official spec
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
   * @abstract Might be implemented might be implemented.
   * @see Component#getInitialState
   *
   * @return {Object} default properties
  ###
  initState: ->
    {}

  ###*
   * Calls initState method.
   *
   * @private
   * @abstract Shouldn't be implemented.
   * @see Component#initState
   * @see http://goo.gl/ngXVLl
   *   method official spec
   * @see http://goo.gl/w97dup
   *   antipattern
   *
   * @return {Object} state object
  ###
  getInitialState: ->
    @initState arguments...

  ###*
   * Cascade method for componentWillReceiveProps.
   * Place here the code manipulations when component
   * receive properties from it's parent component.
   * Invoked when a component is receiving new props.
   * This method is not called for the initial render.
   * Use this as an opportunity to react to a prop transition
   * before render() is called by updating the state using
   * this.setState(). The old props can be accessed via this.props.
   * Calling this.setState() within this function
   * will not trigger an additional render.
   *
   * @abstract Might be implemented
   * @see Component#componentWillReceiveProps
   *
   * @param {Object} nextProps * new properties (not diff)
  ###
  updateProps: (nextProps) ->
    null

  ###*
   * Calls updateProps.
   *
   * @private
   * @abstract Shouldn't be implemented.
   * @see Component#updateProps
   * @see  http://goo.gl/hZpQ6D
   *   method official spec
   * @see http://goo.gl/6p7UxI
   *   componentWillReceiveProps Not Triggered After Mounting
  ###
  componentWillReceiveProps: ->
    @updateProps arguments...

  ###*
   * Calls beforeMount.
   *
   * @abstract Shouldn't be implemented.
   * @private
   * @see Component#beforeMount
   * @see http://goo.gl/eXtGGs
   *   method official spec
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
   * @see http://goo.gl/H8huLH
   *   method official spec
   * @see Component#componentWillMount
  ###
  beforeMount: ->
    null

  ###*
   * Calls onMount
   *
   * @private
   * @abstract Shouldn't be implemented.
   * @see Component#onMount
   * @see http://goo.gl/x2uUl6
   *   method official spec
  ###
  componentDidMount: ->
    @onMount arguments...

  ###*
   * Cascade method for componentDidMount.
   * Invoked once, only on the client (not on the server),
   * immediately after the initial rendering occurs.
   * At this point in the lifecycle, the component has a
   * DOM representation which you can access via
   * this.getDOMNode(). If you want to integrate with
   * other JavaScript frameworks, set timers using
   * setTimeout or setInterval, or send AJAX requests,
   * perform those operations in this method.
   *
   * @abstract Might be implemented.
   * @see Component#componentWillMount
   *
   * @return {[type]} [description]
  ###
  onMount: ->
    null

  ###*
   * Calls willUpdate.
   *
   * @abstract Shouldn't be implemented.
   * @see Component#willUpdate
   * @see http://goo.gl/xibdls
   *   method official spec
   *
   * @return {[type]}           [description]
  ###
  shouldComponentUpdate: ->
    @willUpdate arguments...

  ###*
   * Place here the code to permit updates.
   * Invoked before rendering when new props or state are
   * being received. This method is not called
   * for the initial render or when forceUpdate is used.
   * Use this as an opportunity to return false when you're
   * certain that the transition to the new props and state
   * will not require a component update.
   *
   * If shouldComponentUpdate returns false, then render() will be
   * completely skipped until the next state change. (In addition,
   * beforeUpdate and onUpdate will not be called.)
   * By default, shouldComponentUpdate always returns true
   * to prevent subtle bugs when state is mutated in place,
   * but if you are careful to always treat state as
   * immutable and to read only from props and state in
   * render() then you can override shouldComponentUpdate with
   * an implementation that compares the old props and
   * state to their replacements. If performance is a bottleneck, especially
   * with dozens or hundreds of components, use willUpdate
   * to speed up your app.
   *
   * @example
   *   willUpdate: (nextProps, nextState) ->
   *      nextProps.id !== this.props.id
   *
   * @abstract Might be implemented.
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
   * @abstract Shouldn't be implemented.
   * @private
   * @see Component#willUpdateA
   * @see http://goo.gl/UacS26
   *   method official spec
  ###
  componentWillUpdate: ->
    @beforeUpdate arguments...

  ###*
   * Cascade method for componentWillUpdate.
   * Place here the code to resolve component state.
   * Invoked immediately before rendering when new props or
   * state are being received. This method is not called for
   * the initial render. Use this as an opportunity to
   * perform preparation before an update occurs.
   *
   * @abstract Might be implemented.
   * @see Component#componentWillUpdate
   *
   * @param  {Object} nextProps * next properties
   * @param  {Object} nextState * next state
  ###
  beforeUpdate: (nextProps, nextState) ->
    null

  ###*
   * Calls onUpdate method.
   *
   * @todo see to of-doc
   * @see  Component#onUpdate
   * @abstract Shouldn't be implemented.
   * @private
   *
  ###
  componentDidUpdate: ->
    @onUpdate arguments...

  ###*
   * Cascade method for componentWillUpdate.
   * Invoked immediately after the component's updates are
   * flushed to the DOM. This method is not called for
   * the initial render. Use this as an opportunity to
   * operate on the DOM when the component has been updated.
   *
   * @abstract Might be implemented.
   * @see Component#componentWillUpdate
   *
   * @param  {Object} nextProps * next properties
   * @param  {Object} nextState * next state
  ###
  onUpdate: (nextProps, nextState) ->
    null

  ###*
   * Calls onUnmount
   *
   * @abstract Shouldn't be implemented.
   * @see Component#onUnmount
   * @private
   * @todo add @see to of-doc
  ###
  componentWillUnmount: ->
    @onUnmount arguments...

  ###*
   * Cascade method for componentWillUnmount.
   * Invoked immediately before a component is unmounted from the DOM.
   * Perform any necessary cleanup in this method, such as
   * invalidating timers or cleaning up any DOM elements that
   * were created in onMount.
   *
   * @abstract Might be implemented.
   * @todo  doc params
   * @see Component#componentWillUnmount
  ###
  onUnmount: ->
    null

  ###*
   * Renders template. Template by default must be set to
   * template property of component
   * The render() method is required. When called, it should
   * examine this.props and this.state and return a single child component.
   * This child component can be either a virtual representation of
   * a native DOM component (such as <div /> or React.DOM.div())
   * or another composite component that you've defined yourself. You can
   * also return null or false to indicate that you don't want
   * anything rendered. Behind the scenes, React renders a
   * <noscript> tag to work with our current diffing algorithm.
   * When returning null or false, el()
   * will return null. The render() function should be pure, meaning
   * that it does not modify component state, it returns
   * the same result each time it's invoked, and it
   * does not read from or write to the DOM or
   * otherwise interact with the browser (e.g., by using setTimeout). If
   * you need to interact with the browser, perform your work
   * in onMount() or the other lifecycle methods instead. Keeping
   * render() pure makes server rendering more practical and
   * makes components easier to think about.
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
   * Checks if component contains node. Returns jQuery object if
   * component includes element, false otherwise.
   *
   * @example
   *   handleClick: (e) ->
   *     unless @contains, e.target
   *       alert "click outside dropdown, lets collapse it ;)"
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
