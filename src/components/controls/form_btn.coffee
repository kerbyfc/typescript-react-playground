Btn = require 'components/controls/btn'

# Button component with div wrapper for form
module.exports = class FormBtn extends Btn

  # @nodoc
  render: ->
    <div className="form--row submit">
      <Btn {...@props}/>
    </div>
