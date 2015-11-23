"use strict"

App.Behaviors.Organization ?= {}

module.exports = class App.Behaviors.Organization.ADTMName extends Marionette.Behavior

  # *************
  #  PRIVATE
  # *************
  _correct_input_name_for_ad_tm = (el, model) ->
    ad_field = el.dataset.adField

    if model.get(ad_field) is el.value  or  el.value is ""
      el.name = ad_field
      model.set "TM_#{ ad_field }", null
    else
      el.name = "TM_#{ ad_field }"

  _init_template_helpers = (view) ->
    view_template_helpers = _.result( view, "templateHelpers" ) ? {}

    behavior_template_helpers =
      proper_name : (prefix) ->
        if @SOURCE is "tm"  or  @["TM_#{ prefix }"]
          "name=TM_#{ prefix }"
        else
          "name=#{ prefix }"
      is_ad_field : (prefix) ->
        if @SOURCE in ["ad", "dd"]
          "data-ad-field=#{ prefix }"

    view.templateHelpers =
      _.extend view_template_helpers, behavior_template_helpers

  # **************
  #  BACKBONE
  # **************
  events :
    "input [data-ad-field]" : (e) ->
      _correct_input_name_for_ad_tm e.target, @view.model


  # **********
  #  INIT
  # **********
  initialize : ->
    _init_template_helpers @view
