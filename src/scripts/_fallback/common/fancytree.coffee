"use strict"

require "fancytree"

entry = require "common/entry.coffee"

$.ui.fancytree.registerExtension
  name: "protected"
  version: "1.0.0"

  nodeRenderTitle: (ctx, title) ->
    @_super(ctx, title)
