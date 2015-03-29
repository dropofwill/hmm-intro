(function() {
  var app;

  app = window.configApp();

  app.example = void 0;

  window.onload = function() {
    return d3.json("lib/data5.json", function(data) {
      var example_canvas;
      example_canvas = d3.select("body").append("canvas").attr("width", 960).attr("height", 500);
      l('main', app);
      app.example = app.hmm();
      return app.example(data, example_canvas);
    });
  };

}).call(this);

//# sourceMappingURL=main.js.map
