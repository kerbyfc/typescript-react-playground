"use strict"

require "layouts/organization/person_workstation_add_edit.coffee"
require "models/organization/persons.coffee"
require "backbone.syphon"
require "views/organization/person_workstation.coffee"
require "layouts/dialogs/confirm.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

## Класс визуализирует персону в виде миниатюры

    class App.Views.Organization.Person extends App.Views.Organization.PersonWorkstation

      template: "organization/person"


## Вид при отстутствии персон

    class App.Models.Organization.NoPersons extends Marionette.ItemView

      template: "organization/no-persons"




## Коллекция миниатюр персон

    class App.Views.Organization.Persons extends App.Views.Organization.PersonWorkstations

      template: "organization/persons"

      childView: App.Views.Organization.Person

      childViewContainer: "#tm-persons-list"

      emptyView: App.Models.Organization.NoPersons
