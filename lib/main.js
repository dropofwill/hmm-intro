(function() {
  var app, delete_children, generate_data;

  app = window.configApp();

  app.example = void 0;


  /*
   * Create a new HMM visualization and hookup the UI
   * the separation of concerns here is an attempt to make the visualization
   * portable, i.e. you could implement multiple on the same page
  #
   * Whether this was successful is left as an exercise for the reader
   */

  window.onload = function() {
    var canvas, data, height, matrix_el, max_nodes, min_nodes, minus_el, next_el, number_nodes, plus_el, self, width;
    self = this;
    number_nodes = 3;
    max_nodes = 6;
    min_nodes = 1;
    data = generate_data(number_nodes);
    width = 500;
    height = 450;
    canvas = d3.select("#js-mm-1").append("canvas").attr("width", width).attr("height", height);
    matrix_el = d3.select("#js-mm-matrix-1").insert("table", ":first-child");
    app.example = new app.HMM(data, canvas, matrix_el, 1);
    next_el = d3.select("#js-mm-next-1").on("click", function() {
      return app.example.select_next_node();
    });
    plus_el = d3.select("#js-mm-plus-1").on("click", function() {
      if (number_nodes < max_nodes) {
        number_nodes += 1;
      }
      data = generate_data(number_nodes);
      delete_children(matrix_el.node());
      app.example = null;
      app.example = new app.HMM(data, canvas, matrix_el, 1);
      if (number_nodes >= max_nodes) {
        this.classList.add("hide");
      }
      if (minus_el.node().classList.contains("hide")) {
        return minus_el.node().classList.remove("hide");
      }
    });
    return minus_el = d3.select("#js-mm-minus-1").on("click", function() {
      if (number_nodes > 1) {
        number_nodes -= 1;
      }
      data = generate_data(number_nodes);
      delete_children(matrix_el.node());
      app.example = null;
      app.example = new app.HMM(data, canvas, matrix_el, 1);
      if (number_nodes <= min_nodes) {
        this.classList.add("hide");
      }
      if (plus_el.node().classList.contains("hide")) {
        return plus_el.node().classList.remove("hide");
      }
    });
  };


  /*
   * Generate an even probability, ergodic (fully-connected) data set
   */

  generate_data = function(number_nodes) {
    var data, even_prob, ref, sx, sy;
    data = {};
    even_prob = 1 / number_nodes;
    ref = [500, 300], sx = ref[0], sy = ref[1];
    data.nodes = _.times(number_nodes, function(n) {
      return {
        x: sx + n * 10,
        y: sy + n * 10
      };
    });
    data.links = _.flatten(_.times(number_nodes, function(n) {
      return _.times(number_nodes, function(m) {
        return {
          source: n,
          target: m,
          prob: even_prob
        };
      });
    }));
    return data;
  };

  delete_children = function(node) {
    var results;
    results = [];
    while (node.firstChild) {
      results.push(node.removeChild(node.firstChild));
    }
    return results;
  };

}).call(this);

//# sourceMappingURL=main.js.map
