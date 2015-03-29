app = window.configApp()

### exit if already defined ###
if app.hmm?
  l("app.hmm already defined")
  return

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
      .alpha(0.001)
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
      src = new app.Point(x: d.source.x, y: d.source.y)
      trg = new app.Point(x: d.target.x, y: d.target.y)

      if not trg.equals(src)
        vec = trg.sub(src)
        mid = vec.midpoint()
        arc_point = new app.Point(theta: Math.PI + vec.theta, mag: 15, true)
          .add(src).add(mid)
        arc_center = new app.Point(theta: Math.PI + vec.theta, mag: 100, true)
          .add(src).add(mid)

        # l(arc_point)
        # arc_point = mid.rotate(Math.PI/2).add(src)
        # mid = mid.rotate(Math.PI/2, mid).add(src)

        # my.ctx.fillRect(src.x, src.y, 5, 5)
        # my.ctx.fillStyle = "green"
        # my.ctx.fillRect(trg.x, trg.y, 5, 5)
        # my.ctx.fillStyle = "orange"

        my.ctx.globalAlpha = "1"
        my.ctx.fillStyle = "blue"
        # my.ctx.arc(vec.x, vec.y, 10, 0, 2 * Math.PI)
        my.ctx.fillRect(vec.x, vec.y, 5, 5)

        my.ctx.fillStyle = "black"
        # my.ctx.arc(mid.x, mid.y, 10, 0, 2 * Math.PI)
        my.ctx.fillRect(mid.x, mid.y, 5, 5)

        my.ctx.fillStyle = "red"
        # my.ctx.arc(arc_point.x, arc_point.y, 10, 0, 2 * Math.PI)
        my.ctx.fillRect(arc_point.x, arc_point.y, 5, 5)
        my.ctx.fillRect(arc_center.x, arc_center.y, 7, 7)

        my.ctx.moveTo(src.x, src.y)
        my.ctx.lineTo(arc_point.x, arc_point.y)
        my.ctx.lineTo(trg.x, trg.y)

        # pts = link_points(d)
        # mid = rotate(pts.mid, pts.target, Math.PI/2)
        # my.ctx.moveTo(pts.source.x, pts.source.y)
        # my.ctx.lineTo(mid.x, mid.y)
        # my.ctx.lineTo(pts.target.x, pts.target.y)
        # my.ctx.arc(d.target.x, d.target.y, 50, 0, Math.Pi)
        # l(link_points(d))
    my.ctx.stroke()

    # draw nodes
    my.ctx.fillStyle = "darkslategray"
    my.ctx.globalAlpha = "0.5"
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

  ###
  # Rotate a line defined by two Cartesian points by radian rotation
  ###
  rotate = (src, trg, radians) ->
    cos = Math.cos(radians)
    sin = Math.sin(radians)
    ### Apply 2d rotation matrix to get rotated x and y ###
    x: (cos * (trg.x - src.x)) - (sin * (trg.y - src.y)) + src.x
    y: (sin * (trg.x - src.x)) + (cos * (trg.y - src.y)) + src.y

  ###
  # Calculates the Pythagorean theorem
  ###
  magnitude = (dx, dy) ->
    Math.sqrt(dx * dx + dy * dy)

  ###
  # Find the midpoint of the line defined by two points
  ####
  midpoint = (p1, p2) ->
    x: (p1.x + p2.x)/2
    y: (p1.y + p2.y)/2

  ###
  # Find the slope of the line defined by two points
  ###
  slope = (p1, p2) ->
    p2.y - p1.y / p2.x - p1.x

  ###
  # Find the slope perpendicular to a given slope
  ###
  perp = (slope) ->
    ### perpendicular slope is just the negative reciprocal ###
    -1 * 1/slope

  return initialize

l('hmm', app)
