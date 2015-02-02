Component = require "component"
template  = require "./dropdown-tmpl"

class Dropdown extends Component

  template: template

  defaultProps =
    linkClass : ""
    className : ""
    caret     : false
    open      : false

  ###*
   * @nodoc
   * @return {Object} - component props
  ###
  defaultProps: defaultProps

  ###*
   * @nodoc
   * @return {Object} - component state
  ###
  initState: ->
    open: @props.open

  ###*
   * @nodoc
   * @return {Object} - template locals
  ###
  locals: ->
    _.extend @, Router

  ###*
   * Toggle visibility state
   * @return {Void}
  ###
  toggle: (e) ->
    e.preventDefault()
    @setState
      open: not @state.open

  ###*
   * Hide dropdown contents
   * @return {Void}
  ###
  hide: ->
    if @state.open
      @setState
        open: false

  resolveClass: ->
    "#{@props.className} #{@state.open and "open"}"

  resolveLinkClass: ->
    "dropdown-toggle #{@props.linkClass}"

  ###*
   * @nodoc
   * @return {Void} - after component mount manipulations
  ###
  onMount: ->
    # FIXME calls for every instance!
    $ document.body
      .on 'click', (e) =>
        dropdown = $(e.target).closest('.dropdown-component')
        # clicked to another
        another = dropdown[0] isnt @el() and @state.open
        if dropdown.length is 0 or another
          @hide()

module.exports = Dropdown
