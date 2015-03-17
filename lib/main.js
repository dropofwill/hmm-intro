(function() {
  var canvas, context, force, from_polar, graph, height, link_arc, tick, to_polar, width;

  width = 960;

  height = 500;

  graph = void 0;

  canvas = d3.select("body").append("canvas").attr("width", width).attr("height", height);

  force = d3.layout.force().size([width, height]);

  context = canvas.node().getContext("2d");

  d3.json("lib/data.json", function(data) {
    graph = data;
    return force.nodes(graph.nodes).links(graph.links).linkDistance(250).on("tick", tick).start();
  });

  tick = function() {
    context.clearRect(0, 0, width, height);
    context.strokeStyle = "#999";
    context.beginPath();
    graph.links.forEach(function(d) {
      context.moveTo(d.source.x, d.source.y);
      return context.lineTo(d.target.x, d.target.y);
    });
    context.stroke();
    context.fillStyle = "darkslategray";
    context.beginPath();
    graph.nodes.forEach(function(d) {
      context.moveTo(d.x, d.y);
      if (d.hidden) {
        return context.rect(d.x, d.y, 15, 15);
      } else {
        return context.arc(d.x, d.y, 10, 0, 2 * Math.PI);
      }
    });
    return context.fill();
  };

  link_arc = function(d) {
    var cart_source, cart_target, dx, dy, length, polar, polar_source, polar_target, source_r, source_x, source_y, target_r, target_x, target_y;
    source_r = node_scale(d.source.size) || min_node_radius;
    target_r = node_scale(d.target.size) || min_node_radius;
    source_x = d.source.x;
    source_y = d.source.y;
    target_x = d.target.x;
    target_y = d.target.y;
    dx = target_x - source_x;
    dy = target_y - source_y;
    length = Math.sqrt(dx * dx + dy * dy);
    polar = to_polar(dx, dy);
    polar_source = [polar[0], source_r];
    cart_source;
    polar_target = [polar[0], target_r + 5];
    cart_target;
    polar_source[0] -= Math.PI / 4;
    polar_target[0] += Math.PI / 4;
    cart_source = from_polar([source_x, source_y], polar_source);
    cart_target = from_polar([target_x, target_y], polar_target);
    return "M" + source_x + "," + source_y + "A" + length + "," + length + " 0 0,1 " + cart_target[0] + "," + cart_target[1];
  };

  to_polar = function(x, y) {
    var mag, theta;
    theta = Math.atan2(x, y);
    mag = Math.sqrt(x * x + y * y);
    return [theta, mag];
  };

  from_polar = function(start, polar) {
    var x, y;
    x = start[0] + Math.cos(polar[0]) * polar[1];
    y = start[1] - Math.sin(polar[0]) * polar[1];
    return [x, y];
  };

}).call(this);

//# sourceMappingURL=main.js.map
