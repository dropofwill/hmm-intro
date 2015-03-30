(function() {
  var app;

  app = window.configApp();

  app.example = void 0;

  d3.ns.prefix.custom = "http://will-paul.com";

  window.onload = function() {
    return d3.json("lib/data.json", function(data) {
      var bind, canvas;
      canvas = d3.select("body").append("canvas").attr("width", 960).attr("height", 500);
      bind = d3.select("body").append("custom:sketch").attr("width", 900).attr("height", 500);
      l('main', app);
      return app.example = new app.HMM(data, bind, canvas);
    });
  };

}).call(this);

//# sourceMappingURL=main.js.map
