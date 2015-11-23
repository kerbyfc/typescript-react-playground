"use_strict"

###*
 * Empty unified notification abstract view
 * Make new sub classes and define message property with i18n
 * Controllers and modules deprecated to call this class directly.
###
module.exports = class EmptyBlockMessage extends Marionette.ItemView

  className: 'empty-block__message'

  template: 'controls/empty_message'

  templateHelpers: =>
    message: if @key then App.t(@key) else _.result(@, 'message')

  ###*
   * {String} Message to show
  ###
  message: -> '!!!Message not defined @see EmptyBlockMessage.message !!!'

  ###*
   * {String} i18n key of string to show into the block.
   * This option overrides @message method
  ###
  key: null
