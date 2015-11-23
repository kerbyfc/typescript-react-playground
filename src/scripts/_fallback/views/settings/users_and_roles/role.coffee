"use strict"

require "bootstrap"
require "fancytree"

helpers = require "common/helpers.coffee"
require "views/controls/form_view.coffee"

priveledgesSpec = require "settings/priveledges.json"

module.exports = class RoleDialog extends App.Views.Controls.FormView

  template: "settings/users_and_roles/role"

  defaults:
    blocked: false

  events:
    "click ._success": "save"

  ui:
    tree: '.privilegies'

  templateHelpers: ->
    blocked: @blocked
    modal_dialog_title: @title

  initialize: (options) ->
    {@callback, @title, @blocked} = _.defaults(@options, options)

  collectPrivilegies: (data) ->
    privilegies = []

    _.each data.children, (item) =>
      if item.children
        privilegies = _.union privilegies, @collectPrivilegies(item)
      else
        if item.selected
          privilegies.push(item.key)

    return privilegies

  parseError: (xhr) ->
    for key, error of xhr.responseJSON
      switch key
        when 'DISPLAY_NAME'
          @showErrorHint(key, App.t 'settings.roles.role_name_contraint_violation_error')
        else
          @showErrorHint(null, App.t 'global.undefined_error')

  save: (e) ->
    e.preventDefault()

    return if helpers.islock { type: 'role', action: 'edit' }

    data = Backbone.Syphon.serialize @
    data.privileges = @collectPrivilegies @$el.find(".privilegies").fancytree('getTree').toDict(true)

    data.privileges = _.compact _.map data.privileges, (priv) =>
      unless priv[0] is "/"
        return {PRIVILEGE_CODE: priv, ROLE_ID: @model.id}
      false

    if @model.isNew()
      @model.save data,
        wait: true
        success: (model, collection, options) =>
          @collection.add @model

          @destroy()

          @callback() if @callback

        error: (model, xhr, options) =>
          @parseError(xhr)
    else
      @model.save data,
        wait: true
        success: (model, collection, options) =>
          @destroy()

          @callback() if @callback

        error: (model, xhr, options) =>
          @parseError(xhr)


  filterAbilityProduct: (source) ->
    res = []

    for i of source
      role = source[i]
      key = role.key

      if (not key or @user.isAvailableAbility(key))
        children = role.children

        if children
          role.children = @filterAbilityProduct(children)

        if children and role.children.length or not children
          res.push(role)

    return res

  # find selected items in priviledges
  #
  # @param priviledges [ Array        ] priveledges
  # @param vals    [ Array<String|RegExp> ] array of match patterns
  # @return      [ Boolean        ] search result
  #
  find: (priveledges, vals...) ->
    matches = []

    for val in vals

      # 1) to avoid type conversion in cycle
      # 2) to use RegExp::test (faster)
      if _.isString val
        val = new RegExp val

      for p in priveledges
        if val.test p
          matches.push p
    matches


  # generate source for fancytree from
  # priviledges.yml spec
  #
  # @param spec  [ Object ] spec object
  # @param root  [ Array  ] hierarchy path chunks
  # @param state [ Array  ] base priviledges state
  # @param deps  [ Object ] dependencies
  # @param index [ Array  ] key-object index
  # @param depth [ Number ] hierarchy depth
  # @return    [ Array  ] acuumulated data
  #
  genSourceFromSpec: (spec, state, deps = {}, index = [], root = [], depth = 1) ->

    data = []

    for key, val of spec
      if key[0] in ['-', '+', '.']
        sign  = key.slice(1)
        scope = root.join("/")
        path  = root.concat sign
        item  = title: App.t "priviledge." + path.join("/").replace(/[\/:]/g, '_')
        # resolve prefix (only keys with prefixes will be involved)
        switch key[0]

          # go deeper
          when "+", "-"
            item.children = @genSourceFromSpec val, state, deps, index, path, depth + 1
            # + prefix means expanded state
            if key[0] is "+"
              item.expanded = true

          # construct item object
          when "."
            item.key = "#{scope}:#{sign}"

            item.selected = if _.isObject val

              # dependences must be represented with array
              if _.isArray(val.depends)

                for dep, i in val.depends

                  # for convenient usage there are many mappging merges
                  # in yaml spec, and 'scope' keyword in dependence
                  # should be transformed to current scope path val
                  if dep is 'scope'
                    val.depends[i] = scope

                  # register dependency
                  (deps[item.key] ?= []).push val.depends[i]

                # find selected priveledges by patterns
                selected = @find(
                  # avoid searching itself
                  _.without(state, item.key)

                  # search at least one selected dependency
                  val.depends...
                ).length > 0

                # if selection based on dependence
                # item should be disabled & unselectable
                if selected
                  _.extend item,
                    unselectable: true
                    extraClasses: 'disabled'

                # result or default from spec
                selected or val.selected
              else
                val.selected
            else
              # use default from spec
              val

            item.selected or= @find(state, item.key).length > 0

            # accumulate
            index.push item.key

        if @blocked
          _.extend item,
            unselectable: true

        data.push item

    if depth is 1

      # form links object, that represents
      # impact links and dependence links between
      # items
      links =
        impact: []
        dependence: []
      for key, patterns of deps

        # collected dependencies above are patterns,
        # but we must find strict keys
        for trigger in _.without @find(index, patterns...), key
          (links.impact[trigger] ?= []).push key
          (links.dependence[key] ?= []).push trigger

      # output all collected data at the end off recursion
      [data, index, links]
    else
      # accumulate
      data

  # Toggle nodes by its parent selection state
  #
  # @param node [Object] fancytree node
  # @param selected [Boolean] selection state
  #
  affectChildNodes: (node, selected = node.parent.isSelected()) =>
    @affectNode node, selected

  # Toggle node state
  #
  # @param node [Object] fancytree node
  # @param selected [Boolean] selection state to switch
  #
  affectNode: (node, selected) =>
    tree = @ui.tree.fancytree("getTree")

    if node.unselectable
      node.unselectable = false
      if _.any(@links.dependence[node.key],
         (k) -> tree.getNodeByKey(k).isSelected())
        node.setSelected()
        node.unselectable = true

    # some other nodes may be affected
    # by toggling node selection state
    # find nodes, that must be affected
    # with prepared impact links

    if keys = @links.impact[node.key]
      for key in keys
        _node = tree.getNodeByKey key
        if selected
          # select & lock dependent node
          _node.setSelected()
          _node.extraClasses = "disabled"
          _node.unselectable = true
        else
          # find nodes that also affects to this node
          # by prepared dependence links
          triggers = _.filter @links.dependence[_node.key], (k) ->
            tree.getNodeByKey(k).isSelected()

          # if there are no nodes, that locks current
          unless triggers.length
            # unlock it
            _node.extraClasses = ""
            _node.unselectable = false

        #if _node.parent.expanded
        _node.render()

  onShow: ->
    super

    @user = App.Session.currentUser()

    data = @model.toJSON()

    Backbone.Syphon.deserialize @, data

    @privileges = _.map data.privileges, (priv) ->
      priv.PRIVILEGE_CODE

    [@source, @index, @links] = @genSourceFromSpec(
      priveledgesSpec
      @privileges
    )

    @ui.tree.fancytree
      checkbox: true
      selectMode: 3
      icons: false
      select: (event, data) =>
        if data.node.key[0] is '_'
          # если чекается промежуточный узел
          data.node.visit @affectChildNodes
        else
          # узел не промежуточный
          @affectNode data.node, data.node.isSelected()

      source: @filterAbilityProduct @source
      renderNode: @makeTooltip

  # make tooltip for every selectable single tree node
  # (to represent links with another nodes)
  #
  # @param event [Event] mouseenter event
  #
  makeTooltip: (event, data) =>
    node = data.node
    if node.key[0] isnt '/'
      tooltip = ""
      for rel in _.keys @links
        # search dependencies
        if (deps = @links[rel][node.key]) and deps.length
          # form list of priveleges
          list = _.map(deps, (key) ->
            " - " + App.t "priviledge.#{key.replace(/[\/:]/g, '_')}"
          ).join('\n')
          prefix = App.t "settings.roles.#{rel}"
          tooltip += "#{prefix}\n#{list}\n"
      if tooltip
        # set a tooltip
        node.tooltip = tooltip
        $(node.span).find('.fancytree-title').prop('title', tooltip.slice(0, -1))
