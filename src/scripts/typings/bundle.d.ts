/// <reference path="tsd/tsd.d.ts" />
/// <reference path="require.d.ts" />

interface App {
}

interface Window {
  $     : JQueryStatic;
  _     : _.LoDashStatic;
  React : Object;
  app   : App;
}

declare var window: Window;
