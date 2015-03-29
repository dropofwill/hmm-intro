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
    center: undefined

  # main initializer takes data and dom element as input
  initialize = (d, el) ->

    my.force = d3.layout.force()
    my.graph = d
    my.canvas = el
    my.ctx = my.canvas.node().getContext("2d")
    my.center = new app.Point(x: my.width/2, y: my.height/2)

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
    # my.ctx.beginPath()

    my.graph.links.forEach (d) ->
      src = new app.Point(x: d.source.x, y: d.source.y)
      trg = new app.Point(x: d.target.x, y: d.target.y)

      # Check for edges going to the same node
      if not trg.equals(src)
        draw_multinode_arc(src, trg)
      else
        draw_singlenode_arc(src)

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

  ###
  # Draw arc between two different nodes, takes two cartesian points
  # e.g. anything that responds to {x,y}
  ###
  draw_multinode_arc = (src, trg, ctrl_r=40, debug=false) ->
    vec = trg.sub(src)
    mid = vec.midpoint()
    ctrl = new app.Point(theta: Math.PI + vec.theta, mag: ctrl_r)
      .add(src).add(mid)

    draw_quad_curve(src, ctrl, trg)

    if debug
      my.ctx.save()
      my.ctx.globalAlpha = "1"
      my.ctx.fillStyle = "red"
      my.ctx.fillRect(ctrl.x, ctrl.y, 7, 7)
      my.ctx.restore()

  draw_singlenode_arc = (src) ->
    my.ctx.beginPath()
    vec = src.sub(my.center).normalize().add(src)
    my.ctx.arc(vec.x, vec.y, 10, 0, 2 * Math.PI)
    my.ctx.stroke()

  ###
  # Abstraction around quadraticCurveTo using our Point object
  # draws from src to trg, using ctrl as the beizer control-point
  ###
  draw_quad_curve = (src, ctrl, trg) ->
    my.ctx.beginPath()
    my.ctx.moveTo(src.x, src.y)
    my.ctx.quadraticCurveTo(ctrl.x, ctrl.y, trg.x, trg.y)
    my.ctx.stroke()

  return initialize
