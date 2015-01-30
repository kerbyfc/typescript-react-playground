Component = require "component"

module.exports = class MenuLink extends Component

  resolveClassName: ->
    "main_nav--item #{@props.className or ""}"

  render: ->
    <li className={ @resolveClassName() }>
      { @props.children }
    </li>
