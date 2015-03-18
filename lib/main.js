(function() {
  var DEBUG, app, l,
    slice = [].slice;

  app = app || {};

  app.hmm = function() {
    var initialize, link_arc, link_points, magnitude, midpoint, my, perp, rotate, slope, tick, to_cart, to_polar;
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
      square_width: 15
    };
    initialize = function(d, el) {
      my.force = d3.layout.force();
      my.graph = d;
      my.canvas = el;
      my.ctx = my.canvas.node().getContext("2d");
      return my.force.nodes(my.graph.nodes).size([my.width, my.height]).links(my.graph.links).linkDistance(my.link_dist).on("tick", tick).start();
    };
    tick = function() {
      my.ctx.clearRect(0, 0, my.width, my.height);
      my.ctx.strokeStyle = my.stroke_style;
      my.ctx.beginPath();
      my.graph.links.forEach(function(d) {
        var mid, pts;
        pts = link_points(d);
        mid = rotate(pts.mid, pts.target, Math.PI / 2);
        my.ctx.moveTo(pts.source.x, pts.source.y);
        my.ctx.lineTo(mid.x, mid.y);
        return my.ctx.lineTo(pts.target.x, pts.target.y);
      });
      my.ctx.stroke();
      my.ctx.fillStyle = "darkslategray";
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
    link_arc = function(d) {
      var cart_source, cart_target, dx, dy, length, polar, polar_source, polar_target, source_r, target_r;
      source_r = d.source.size || my.node_radius;
      target_r = d.target.size || my.node_radius;
      dx = d.target.x - d.source.x;
      dy = d.target.y - d.source.y;
      length = magnitude(dx, dy);
      polar = to_polar(dx, dy);
      polar_source = {
        theta: polar.theta,
        r: source_r
      };
      polar_target = {
        theta: polar.theta,
        r: target_r + 5
      };
      polar_source.theta -= Math.PI / 4;
      polar_target.theta += Math.PI / 4;
      cart_source = to_cart(d.source, polar_source);
      cart_target = to_cart(d.target, polar_target);
      return "M" + d.source.x + "," + d.source.y + "A" + length + "," + length + " 0 0,1 " + cart_target.y + "," + cart_target.y;
    };
    link_points = function(d) {
      var mid;
      mid = midpoint(d.source, d.target);
      return {
        source: _.pick(d.source, ["x", "y"]),
        mid: mid,
        target: _.pick(d.target, ["x", "y"])
      };
    };
    to_polar = function(x, y) {
      var mag, theta;
      theta = Math.atan2(x, y);
      mag = magnitude(x, y);
      return {
        theta: theta,
        mag: mag
      };
    };
    to_cart = function(start, polar) {
      var x, y;
      x = start.x + Math.cos(polar.theta) * polar.r;
      y = start.y - Math.sin(polar.theta) * polar.r;
      return {
        x: x,
        y: y
      };
    };
    rotate = function(src, trg, radians) {
      var cos, sin;
      cos = Math.cos(radians);
      sin = Math.sin(radians);
      return {
        x: (cos * (trg.x - src.x)) - (sin * (trg.y - src.y)) + src.x,
        y: (sin * (trg.x - src.x)) + (cos * (trg.y - src.y)) + src.y
      };
    };
    magnitude = function(dx, dy) {
      return Math.sqrt(dx * dx + dy * dy);
    };
    midpoint = function(p1, p2) {
      return {
        x: (p1.x + p2.x) / 2,
        y: (p1.y + p2.y) / 2
      };
    };
    slope = function(p1, p2) {
      return p2.y - p1.y / p2.x - p1.x;
    };
    perp = function(slope) {
      return -1 * 1 / slope;
    };
    return initialize;
  };

  DEBUG = true;

  l = function() {
    var vals;
    vals = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return vals.forEach(function(v) {
      if (DEBUG) {
        return console.log(v);
      }
    });
  };

  app = app || {};

  app.example1 = void 0;

  window.onload = function() {
    return d3.json("lib/data.json", function(data) {
      var a_canvas;
      a_canvas = d3.select("body").append("canvas").attr("width", 960).attr("height", 500);
      app.example1 = app.hmm();
      return app.example1(data, a_canvas);
    });
  };

}).call(this);

//# sourceMappingURL=main.js.map
