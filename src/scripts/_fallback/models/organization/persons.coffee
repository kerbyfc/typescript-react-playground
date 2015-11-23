"use strict"

require "models/organization/person_workstation.coffee"
require "models/organization/workstations.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Models.Organization ?= {}

## Модель представляет данные об одной персоне

    class App.Models.Organization.Person extends App.Models.Organization.PersonWorkstation

      idAttribute: "PERSON_ID"

      urlRoot: "#{App.Config.server}/api/ldapPerson"

      initialize: ->
        if @get("SOURCE") isnt "ad" and @get("SOURCE") isnt "dd"
          @validation =
            "GIVENNAME":
              maxLength : 64
              required  : true

            "SN":
              maxLength : 64
              required  : true

      parse: (response) ->
        resp = response.data  or  response

        if resp.workstations
          unless @get("workstations")?
            resp.workstations = new App.Models.Organization.Workstations resp.workstations[..]
          else
            @get("workstations").reset resp.workstations[..]
            delete resp.workstations

        super resp

      labels:
        "GIVENNAME" : App.t 'form-fields.firstName'
        "SN"        : App.t 'form-fields.lastName'

      type: "person"




## Коллекция представляет совокупность моделей персон

    class App.Models.Organization.Persons extends App.Models.Organization.PersonWorkstations

      # ************
      #  PUBLIC
      # ************
      from_group_fetch_prefix : "p2g_all"

      type : "persons"


      # **************
      #  BACKBONE
      # **************
      model: App.Models.Organization.Person


