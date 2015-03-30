(function() {
  var app;

  app = window.configApp();

  app.example = void 0;

  window.onload = function() {
    return d3.json("lib/data.json", function(data) {
      var canvas, dim, matrix_el;
      dim = 500;
      canvas = d3.select("#js-mm-1").append("canvas").attr("width", dim).attr("height", dim);
      matrix_el = d3.select("#js-mm-matrix-1").append("table");
      l('main', app);
      return app.example = new app.HMM(data, canvas, matrix_el, 1);
    });
  };

}).call(this);

//# sourceMappingURL=main.js.map
