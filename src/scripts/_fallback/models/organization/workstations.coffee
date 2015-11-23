"use strict"

require "models/organization/person_workstation.coffee"
require "models/organization/persons.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Models.Organization ?= {}

    class App.Models.Organization.Workstation extends App.Models.Organization.PersonWorkstation

      validation:
        "DISPLAY_NAME":
          required  : true

      labels:
        "DISPLAY_NAME" : App.t 'form-fields.name'

      idAttribute: "WORKSTATION_ID"

      urlRoot: "#{App.Config.server}/api/ldapWorkstation"

      parse: (response) ->
        resp = response.data  or  response

        if resp.persons
          unless @get("persons")?
            resp.persons = new App.Models.Organization.Persons resp.persons[..]
          else
            @get("persons").reset resp.persons[..]
            delete resp.persons

        super resp

      type: "workstation"



    class App.Models.Organization.Workstations extends App.Models.Organization.PersonWorkstations

      # ************
      #  PUBLIC
      # ************
      from_group_fetch_prefix : "w2g_all"

      type : "workstations"


      # **************
      #  BACKBONE
      # **************
      model: App.Models.Organization.Workstation


