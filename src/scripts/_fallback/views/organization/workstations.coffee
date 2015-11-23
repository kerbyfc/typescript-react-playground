"use strict"

require "views/organization/person_workstation.coffee"

App.module "Organization",
  startWithParent: false
  define: (Organization, App, Backbone, Marionette, $) ->

    App.Views.Organization ?= {}

## Данный класс представляет одну рабочую станцию в виде миниатюры

    class App.Views.Organization.Workstation extends App.Views.Organization.PersonWorkstation

      template: "organization/workstation"


    class App.Views.Organization.NoWorkstations extends Marionette.ItemView

      template: "organization/no-workstations"


## Данный класс представляет коллекцию рабочих станций в виде миниатюр

    class App.Views.Organization.Workstations extends App.Views.Organization.PersonWorkstations

      childView: App.Views.Organization.Workstation

      childViewContainer : "#tm-workstations-list"

      template: "organization/workstations"

      emptyView: App.Views.Organization.NoWorkstations
