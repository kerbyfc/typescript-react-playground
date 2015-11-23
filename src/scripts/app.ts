/// <reference path="typings/bundle.d.ts" />

import $      = require("jquery");
import _      = require("lodash");
import React  = require("react");
import Router = require("react-router");

window.$     = $;
window._     = _
window.React = React

/*
var app = {
  config    : require("config.json"),
  templates : require("templates"),
  session   : require("session"),
  router    : require("router")
};
*/

var session = require("session.coffee");

class App implements App {

  public session = session;

  constructor(private modules: Array<ReactRouter.Route>) {
    this.session.start(modules);
  }

  navigate(route: any):any {
    if (history) {
      history.pushState(null, "signin", "signin");
      return history.go(1);
    } else {
      return location.hash = "/" + route;
    }
  };

}

window.app = new App([
  require("modules/reports/bootstrap.coffee")
]);
