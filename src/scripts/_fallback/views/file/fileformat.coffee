"use strict"

require "views/controls/grid.coffee"

exports.FileEmpty = class FileEmpty extends Marionette.ItemView

  template: "file/empty"

  className: "content"

exports.Fileformat = class Fileformat extends App.Views.Controls.ContentGrid

  template: "file/fileformat"

  behaviors: ->
    behaviors = super

    Toolbar : behaviors.Toolbar
    Search  : {}
