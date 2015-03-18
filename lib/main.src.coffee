app = app || {}

# Closure for constructing an HMM model on arbitrary data
app.hmm = () ->
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

    my.force = d3.layout.force()
    my.graph = d
    my.canvas = el
    my.ctx = my.canvas.node().getContext("2d")

    my.force
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
      pts = link_points(d)
      mid = rotate(pts.mid, pts.target, Math.PI/2)
      my.ctx.moveTo(pts.source.x, pts.source.y)
      my.ctx.lineTo(mid.x, mid.y)
      my.ctx.lineTo(pts.target.x, pts.target.y)
      # my.ctx.arc(d.target.x, d.target.y, 50, 0, Math.Pi)
      # l(link_points(d))
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
    source_r = d.source.size || my.node_radius
    target_r = d.target.size || my.node_radius
    dx = d.target.x - d.source.x
    dy = d.target.y - d.source.y
    length = magnitude(dx, dy)

    polar = to_polar(dx, dy)
    polar_source = { theta: polar.theta, r: source_r }
    polar_target = { theta: polar.theta, r: target_r + 5 }

    polar_source.theta -= Math.PI/4
    polar_target.theta += Math.PI/4

    cart_source = to_cart(d.source, polar_source)
    cart_target = to_cart(d.target, polar_target)

    return "M" + d.source.x + "," + d.source.y +
           "A" + length + "," + length + " 0 0,1 " +
           cart_target.y + "," + cart_target.y

  link_points = (d) ->
    mid = midpoint(d.source, d.target)

    source: _.pick(d.source, ["x", "y"])
    mid   : mid
    target: _.pick(d.target, ["x", "y"])

  to_polar = (x, y) ->
    theta = Math.atan2(x, y)
    mag = magnitude(x, y)

    theta: theta
    mag: mag

  to_cart = (start, polar) ->
    x = start.x + Math.cos(polar.theta) * polar.r
    y = start.y - Math.sin(polar.theta) * polar.r

    x: x
    y: y

  # Cartesian rotation
  rotate = (src, trg, radians) ->
    cos = Math.cos(radians)
    sin = Math.sin(radians)
    # apply 2d rotation matrix to get rotated x and y
    x: (cos * (trg.x - src.x)) - (sin * (trg.y - src.y)) + src.x
    y: (sin * (trg.x - src.x)) + (cos * (trg.y - src.y)) + src.y

  # Calculates the Pythagorean theorem
  magnitude = (dx, dy) ->
    Math.sqrt(dx * dx + dy * dy)

  midpoint = (p1, p2) ->
    x: (p1.x + p2.x)/2
    y: (p1.y + p2.y)/2

  slope = (p1, p2) ->
    p2.y - p1.y / p2.x - p1.x

  perp = (slope) ->
    -1 * 1/slope

  return initialize

DEBUG = true

l = (vals...) ->
  vals.forEach (v) ->
    console.log(v) if DEBUG

app = app || {}
app.example1 = undefined

window.onload = () ->
  d3.json "lib/data.json", (data) ->
    a_canvas = d3.select("body").append("canvas")
      .attr("width", 960)
      .attr("height", 500)

    app.example1 = app.hmm()
    app.example1(data, a_canvas)
