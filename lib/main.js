(function() {
  var app;

  app = window.configApp();

  app.example = void 0;

  window.onload = function() {
    return d3.json("lib/data4.json", function(data) {
      var canvas, height, matrix_el, next_el, width;
      width = 500;
      height = 450;
      canvas = d3.select("#js-mm-1").append("canvas").attr("width", width).attr("height", height);
      matrix_el = d3.select("#js-mm-matrix-1").insert("table", ":first-child");
      app.example = new app.HMM(data, canvas, matrix_el, 1);
      return next_el = d3.select("#js-mm-next-1").on("click", function() {
        return app.example.select_next_node();
      });
    });
  };

}).call(this);

//# sourceMappingURL=main.js.map
