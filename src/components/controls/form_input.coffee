Input = require "components/controls/input"

###*
 * Wrapped input input to use it in forms
 * It also renders label if label props were passed
###
module.exports = class FormInput extends Input

  ###*
   * Resolve label class name
   * @param  { Object } p - props
   * @return { String }   - component
  ###
  renderLabelClassName: (p) ->
    "form--label " + (p.className or "size-full")

  ###*
   * Render label element
   * @param  { Object       } p - props
   * @return { ReactElement }   - component
  ###
  renderLabel: (p) ->
    <label className = @renderLabelClassName(p) >
      { p.text }
    </label>

  ###*
   * Wrap input with div.form--elem and
   * render label before
   * @return { ReactElement } - component
  ###
  render: ->
    <div className="form--row">
      { @renderLabel @props.label if @props.label? }
      <div className="form--elem">
        <Input {...@props}/>
      </div>
    </div>
