"use strict"

class StatTypes extends Marionette.ItemView

  tagName: "label"

  className: "dashboardCreateWidget__item"

  triggers:
    "click .dashboardCreateWidget__add-btn" : "addWidget"

  template: "dashboards/dialogs/stattype"


module.exports = class SelectWidgetsDialog extends Marionette.CompositeView

  childView: StatTypes

  childViewContainer: ".widget_create_popup"

  template: "dashboards/dialogs/select_widgets"
