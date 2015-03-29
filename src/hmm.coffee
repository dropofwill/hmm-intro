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
    stroke_width: "4"
    fill_style: "#darkslategray"
    node_radius: 20
    square_width: 20
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
      .links(my.graph.links)
      .size([my.width, my.height])
      .alpha(0.001)
      .linkDistance(my.link_dist)
      .on("tick", tick)
      .start()

  tick = () ->
    my.ctx.clearRect(0, 0, my.width, my.height)
    my.ctx.strokeStyle = my.stroke_style
    my.ctx.lineWidth = my.stroke_width

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
    my.ctx.globalAlpha = ".4"
    my.ctx.beginPath()

    my.graph.nodes.forEach (d) ->
      my.ctx.moveTo(d.x, d.y)

      if not d.hidden
        my.ctx.arc(d.x, d.y, my.node_radius, 0, 2 * Math.PI)
      # else
      #   my.ctx.rect(d.x, d.y, my.square_width, my.square_width)

    my.ctx.fill()

  ###
  # Draw arc between two different nodes, takes two Points and optionally the
  # nodes radius (r) and how far out the quads ctrl point goes out
  ###
  draw_multinode_arc = (src, trg, r=20, ctrl_r=40) ->
    vec = trg.sub(src)
    # Could stop drawing src from center with the following:
    # src = vec.normalize().mul(20).rotate(Math.PI/4).add(src)
    #
    ### Use relative vector between src and trg to get the angle
    # then expand to just a little bit larger than the nodes radius
    # then rotate around so that it is no longer at the center
    # finally convert the vector back to abs coordinates by adding trg ###
    trg = vec.normalize().mul(r + 5).rotate(3 * Math.PI / 4).add(trg)
    mid = vec.midpoint()
    ctrl = new app.Point(theta: Math.PI + vec.theta, mag: ctrl_r)
      .add(src).add(mid)

    draw_quad_curve(src, ctrl, trg)
    draw_quad_arrow(src, ctrl, trg)

    # my.ctx.save()
    # my.ctx.globalAlpha = "1"
    # my.ctx.fillStyle = "red"
    # my.ctx.fillRect(ctrl.x, ctrl.y, 7, 7)
    # my.ctx.restore()

  draw_singlenode_arc = (src, r=40) ->
    my.ctx.beginPath()
    vec = src.sub(my.center).normalize().mul(r).add(src)
    # l(vec)
    my.ctx.arc(vec.x, vec.y, r, 0, 2 * Math.PI)
    my.ctx.stroke()

  draw_quad_arrow = (src, ctrl, trg) ->
    arrow_angle = Math.atan2(ctrl.x - trg.x, ctrl.y - trg.y) + Math.PI
    arrow_width = 15
    shift = Math.PI / 6

    my.ctx.beginPath()
    ### Math from here: http://stackoverflow.com/questions/27778951/drawing-an-arrow-on-an-html5-canvas-quadratic-curve ###
    my.ctx.moveTo(trg.x - (arrow_width * Math.sin(arrow_angle - shift)),
                  trg.y - (arrow_width * Math.cos(arrow_angle - shift)))
    my.ctx.lineTo(trg.x, trg.y)
    my.ctx.lineTo(trg.x - (arrow_width * Math.sin(arrow_angle + shift)),
                  trg.y - (arrow_width * Math.cos(arrow_angle + shift)))
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
