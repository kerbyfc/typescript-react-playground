Component = require "component"
template  = require "./<%= filename %>-tmpl"
<% if (deps) { %>
requiredComponents =
  <% _.each(deps, function(dep, comp) { %><%= comp %>: require "<%= dep %>"
  <%})%><%}%>
class <%= component %> extends Component

  template: template
  <% if (complete) { %>
  ####################################################
  # INITIALIZATION
  <% } %>
  ###*
   * @nodoc
   * @return {Object} - component props
  ###
  defaultProps: ->
    {}

  ###*
   * @nodoc
   * @return {Object} - component state
  ###
  initState: ->
    {}

  ###*
   * @nodoc
   * @return {Void} - before mount non-async manipulations
  ###
  beforeMount: ->
    super
  <% if (complete) { %>
  ####################################################
  # UPDATE CYCLE

  ###*
   * @nodoc
   * @return {Boolean} - update decision
  ###
  willUpdate: ->
    true
  <% } %>
  ###*
   * @nodoc
   * @return {Void} - state non-affecting manipulations
  ###
  beforeUpdate: ->
    super

  ###*
   * @nodoc
   * @return {Void} - state non-affection manipulations
  ###
  onUpdate: ->
    super
  <% if (complete) { %>
  ####################################################
  # RENDERING
  <% } %>
  ###*
   * @nodoc
   * @return {Object} - template locals
  ###
  locals: -> <% if (deps) { %>
    _.extend @, requiredComponents
    <% } else { %>
    @
    <% } %> <% if (complete) { %>
  ###*
   * @nodoc
   * @return {React.Element} - react virtual dom
  ###
  render: ->
    @template _.extend {}, @, @locals()

  ####################################################
  # FINITE ACTIONS
  <% } %>
  ###*
   * @nodoc
   * @return {Void} - after component mount manipulations
  ###
  onMount: ->
    super

module.exports = <%= component %>
