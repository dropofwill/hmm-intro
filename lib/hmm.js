(function() {
  var app;

  app = window.configApp();


  /* exit if already defined */

  if (app.hmm != null) {
    l("app.hmm already defined");
    return;
  }

  app.hmm = function() {
    var draw_multinode_arc, draw_quad_curve, draw_singlenode_arc, initialize, my, tick;
    my = {
      graph: void 0,
      force: void 0,
      canvas: void 0,
      ctx: void 0,
      width: 960,
      height: 500,
      link_dist: 200,
      stroke_style: "#999999",
      fill_style: "#darkslategray",
      node_radius: 10,
      square_width: 15,
      center: void 0
    };
    initialize = function(d, el) {
      my.force = d3.layout.force();
      my.graph = d;
      my.canvas = el;
      my.ctx = my.canvas.node().getContext("2d");
      my.center = new app.Point({
        x: my.width / 2,
        y: my.height / 2
      });
      return my.force.nodes(my.graph.nodes).size([my.width, my.height]).alpha(0.001).links(my.graph.links).linkDistance(my.link_dist).on("tick", tick).start();
    };
    tick = function() {
      my.ctx.clearRect(0, 0, my.width, my.height);
      my.ctx.strokeStyle = my.stroke_style;
      my.graph.links.forEach(function(d) {
        var src, trg;
        src = new app.Point({
          x: d.source.x,
          y: d.source.y
        });
        trg = new app.Point({
          x: d.target.x,
          y: d.target.y
        });
        if (!trg.equals(src)) {
          return draw_multinode_arc(src, trg);
        } else {
          return draw_singlenode_arc(src);
        }
      });
      my.ctx.fillStyle = "darkslategray";
      my.ctx.globalAlpha = "0.5";
      my.ctx.beginPath();
      my.graph.nodes.forEach(function(d) {
        my.ctx.moveTo(d.x, d.y);
        if (d.hidden) {
          return my.ctx.rect(d.x, d.y, 15, 15);
        } else {
          return my.ctx.arc(d.x, d.y, 10, 0, 2 * Math.PI);
        }
      });
      return my.ctx.fill();
    };

    /*
     * Draw arc between two different nodes, takes two cartesian points
     * e.g. anything that responds to {x,y}
     */
    draw_multinode_arc = function(src, trg, ctrl_r, debug) {
      var ctrl, mid, vec;
      if (ctrl_r == null) {
        ctrl_r = 40;
      }
      if (debug == null) {
        debug = false;
      }
      vec = trg.sub(src);
      mid = vec.midpoint();
      ctrl = new app.Point({
        theta: Math.PI + vec.theta,
        mag: ctrl_r
      }).add(src).add(mid);
      draw_quad_curve(src, ctrl, trg);
      if (debug) {
        my.ctx.save();
        my.ctx.globalAlpha = "1";
        my.ctx.fillStyle = "red";
        my.ctx.fillRect(ctrl.x, ctrl.y, 7, 7);
        return my.ctx.restore();
      }
    };
    draw_singlenode_arc = function(src) {
      var vec;
      my.ctx.beginPath();
      vec = src.sub(my.center).normalize().add(src);
      my.ctx.arc(vec.x, vec.y, 10, 0, 2 * Math.PI);
      return my.ctx.stroke();
    };

    /*
     * Abstraction around quadraticCurveTo using our Point object
     * draws from src to trg, using ctrl as the beizer control-point
     */
    draw_quad_curve = function(src, ctrl, trg) {
      my.ctx.beginPath();
      my.ctx.moveTo(src.x, src.y);
      my.ctx.quadraticCurveTo(ctrl.x, ctrl.y, trg.x, trg.y);
      return my.ctx.stroke();
    };
    return initialize;
  };

}).call(this);

//# sourceMappingURL=hmm.js.map
