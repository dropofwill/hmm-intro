(function() {
  var app;

  app = window.configApp();


  /* exit if already defined */

  if (app.hmm != null) {
    l("app.hmm already defined");
    return;
  }

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
      return my.force.nodes(my.graph.nodes).size([my.width, my.height]).alpha(0.001).links(my.graph.links).linkDistance(my.link_dist).on("tick", tick).start();
    };
    tick = function() {
      my.ctx.clearRect(0, 0, my.width, my.height);
      my.ctx.strokeStyle = my.stroke_style;
      my.graph.links.forEach(function(d) {
        var arc_center, arc_point, mid, r, src, start_angle, trg, vec;
        src = new app.Point({
          x: d.source.x,
          y: d.source.y
        });
        trg = new app.Point({
          x: d.target.x,
          y: d.target.y
        });
        if (!trg.equals(src)) {
          vec = trg.sub(src);
          mid = vec.midpoint();
          arc_point = new app.Point({
            theta: Math.PI + vec.theta,
            mag: 15
          }, true).add(src).add(mid);
          arc_center = new app.Point({
            theta: Math.PI + vec.theta,
            mag: 40
          }, true).add(src).add(mid);
          r = arc_center.get_dist(trg);
          start_angle = Math.atan2(arc_center.x - trg.x, arc_center.y - trg.y);
          my.ctx.beginPath();
          my.ctx.moveTo(src.x, src.y);
          my.ctx.quadraticCurveTo(arc_center.x, arc_center.y, trg.x, trg.y);
          my.ctx.globalAlpha = "1";
          my.ctx.fillStyle = "red";
          my.ctx.fillRect(arc_center.x, arc_center.y, 7, 7);
          return my.ctx.stroke();
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

    /*
     * Rotate a line defined by two Cartesian points by radian rotation
     */
    rotate = function(src, trg, radians) {
      var cos, sin;
      cos = Math.cos(radians);
      sin = Math.sin(radians);
      return {

        /* Apply 2d rotation matrix to get rotated x and y */
        x: (cos * (trg.x - src.x)) - (sin * (trg.y - src.y)) + src.x,
        y: (sin * (trg.x - src.x)) + (cos * (trg.y - src.y)) + src.y
      };
    };

    /*
     * Calculates the Pythagorean theorem
     */
    magnitude = function(dx, dy) {
      return Math.sqrt(dx * dx + dy * dy);
    };

    /*
     * Find the midpoint of the line defined by two points
     */
    midpoint = function(p1, p2) {
      return {
        x: (p1.x + p2.x) / 2,
        y: (p1.y + p2.y) / 2
      };
    };

    /*
     * Find the slope of the line defined by two points
     */
    slope = function(p1, p2) {
      return p2.y - p1.y / p2.x - p1.x;
    };

    /*
     * Find the slope perpendicular to a given slope
     */
    perp = function(slope) {

      /* perpendicular slope is just the negative reciprocal */
      return -1 * 1 / slope;
    };
    return initialize;
  };

  l('hmm', app);

}).call(this);

//# sourceMappingURL=hmm.js.map
