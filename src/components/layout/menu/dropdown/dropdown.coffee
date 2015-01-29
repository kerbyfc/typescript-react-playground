Component = require "component"
MenuLink  = require "./link"

module.exports = class MenuDropdown extends Component

  ###*
   * @nodoc
  ###
  initState: ->
    open: false

  # @nodoc
  onMount: ->
    $ document.body
      .on 'click', =>
        @setState
          open: false

  ###*
   * Toggle visibility state
   * @return {Void}
  ###
  toggle: ->
    @setState
      open: not @state.open

  ###*
   * Hide dropdown contents
   * @return {Void}
  ###
  hide: ->
    @setState
      open: false

  # @nodoc
  render: ->
    <MenuLink className = { @state.open and "open" } >
      {[
        <a
          className = "main_nav--link"
          onClick   = @toggle
          onBlur    = @hide
          >
          { @props.name }
        </a>

        if @state.open
          <ul className="main_nav--dropdown">
            { @props.children }
          </ul>
      ]}
    </MenuLink>
