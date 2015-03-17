d3.json "lib/data.json", (data) ->
  my.graph = data

# Closure for constructing an HMM model on arbitrary data
hmm ->
  my =
    graph: undefined
    force: undefined
    canvas: undefined
    ctx: undefined

    width: 960
    height: 500
    link_dist: 200
    stroke_style: "#999999"
    fill_style: "#darkslategray"
    node_radius: 10
    square_width: 15

  # main initializer takes data and dom element as input
  initialize = (d, el) ->
    my.canvas = d3.select("body").append("canvas")
      .attr("width", my.width)
      .attr("height", my.height)

    my.force = d3.layout.force()
    my.graph = d
    my.ctx = canvas.node().getContext("2d")

    force
      .nodes(my.graph.nodes)
      .size([my.width, my.height])
      .links(my.graph.links)
      .linkDistance(my.link_dist)
      .on("tick", tick)
      .start()

  tick = () ->
    my.ctx.clearRect(0, 0, my.width, my.height)

    # draw links
    my.ctx.strokeStyle = my.stroke_style
    my.ctx.beginPath()

    my.graph.links.forEach (d) ->
      my.ctx.moveTo(d.source.x, d.source.y)
      # my.ctx.arc(d.target.x, d.target.y, 50, 0, Math.Pi)
      my.ctx.lineTo(d.target.x, d.target.y)
    my.ctx.stroke()

    # draw nodes
    my.ctx.fillStyle = "darkslategray"
    my.ctx.beginPath()

    my.graph.nodes.forEach (d) ->
      my.ctx.moveTo(d.x, d.y)

      if d.hidden
        my.ctx.rect(d.x, d.y, 15, 15)
      else
        my.ctx.arc(d.x, d.y, 10, 0, 2 * Math.PI)

    my.ctx.fill()

  link_arc = (d) ->
    # Draw arcs between the nodes d.source and d.target, but do so from the
    # edge of the nodes radius at a 45 degree angle from the direct line.
    # This is so the arrow heads are not hidden by really large nodes
    source_r = node_scale(d.source.size) || min_node_radius
    target_r = node_scale(d.target.size) || min_node_radius
    source_x = d.source.x
    source_y = d.source.y
    target_x = d.target.x
    target_y = d.target.y
    dx = target_x - source_x
    dy = target_y - source_y
    length = Math.sqrt(dx * dx + dy * dy)
    polar = to_polar(dx, dy)
    polar_source = [polar[0], source_r]
    cart_source
    polar_target = [polar[0], target_r+5]
    cart_target

    polar_source[0] -= Math.PI/4
    polar_target[0] += Math.PI/4
    cart_source = from_polar([source_x, source_y], polar_source)
    cart_target = from_polar([target_x, target_y], polar_target)

    return "M" + source_x + "," + source_y +
           "A" + length + "," + length + " 0 0,1 " +
           cart_target[0] + "," + cart_target[1]

  to_polar = (x, y) ->
    theta = Math.atan2(x, y)
    mag = Math.sqrt(x * x + y * y)
    [theta, mag]

  from_polar = (start, polar) ->
    x = start[0] + Math.cos(polar[0]) * polar[1]
    y = start[1] - Math.sin(polar[0]) * polar[1]
    return [x, y]

  return initialize
