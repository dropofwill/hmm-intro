(function() {
  "use strict";

  /* Dev Mode: console.logs are running
   * window.DEBUG = true
   * Prod Mode: console.logs are off
   * window.DEBUG = false
   */
  var slice = [].slice;

  window.DEBUG = true;


  /*
   * l(vals...) allows for easy debug toggling with the global constant DEBUG
   * Pass in as many arguments as you like and they will be logged out
   */

  window.l = function() {
    var vals;
    vals = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    if (DEBUG) {
      return console.log.apply(console, vals);
    }
  };


  /*
   * Defines a function which creates or adds onto an existing object in the
   * global scope
  #
   * prop: global property on the window object
   */

  window.configGlobal = function(prop) {
    return function() {
      return window[prop] = window[prop] || {};
    };
  };


  /*
   * Inclusive random range between to floats a, b
   */

  window.inc_random = function(lower, upper) {
    if (lower == null) {
      lower = 0;
    }
    if (upper == null) {
      upper = 1;
    }
    return lower + Math.floor(Math.random() * (upper - lower + 1));
  };

  window.configApp = configGlobal("app");

}).call(this);

//# sourceMappingURL=helpers.js.map
