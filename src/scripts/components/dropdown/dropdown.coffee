###*
 * Dropdown component. Can render list of items with `li` tag,
 * or render custom content.
###
class Dropdown extends Component

  template: JSX.dropdown

  defaultProps =
    linkClass : ""
    className : ""
    caret     : false
    open      : false

  # @nodoc
  # @return [Object] - component props
  #
  defaultProps: defaultProps

  # @nodoc
  # @return [Object] - component state
  #
  initState: ->
    open: @props.open

  # @nodoc
  # @return [Object] - template locals
  #
  locals: ->
    _.extend @, Router

  # Toggle visibility state
  # @return [Void]
  #
  toggle: (e) ->
    e.preventDefault()
    @setState
      open: not @state.open

  # Hide dropdown contents
  # @return [Void]
  #
  hide: ->
    if @state.open
      @setState
        open: false

  resolveClass: ->
    "#{@props.className} #{@state.open and "open"}"

  resolveLinkClass: ->
    "dropdown-toggle #{@props.linkClass}"

  # @nodoc
  # @return [Void] - after component mount manipulations
  #
  onMount: ->
    # FIXME calls for every instance!
    $ document
      .on 'click', @handleDocumentClick

  handleDocumentClick: (e) ->
    if dropdown = $(e.target).closest('.dropdown-component')[0]
      # clicked to another
      unless dropdown.dataset.reactid is @el().dataset.reactid
        @hide()
    else
      @hide()

  onUnmount: ->
    $ document
      .off 'click', @handleDocumentClick

module.exports = Dropdown
