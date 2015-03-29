app = window.configApp()

### exit if already defined ###
if app.hmm?
  l("app.hmm already defined")
  return

# Closure for constructing an HMM model on arbitrary data
class HMM

  # main initializer takes data and dom element as input
  constructor: (d, el) ->
    @force = d3.layout.force()
    @graph = d
    @canvas = el
    @ctx = @canvas.node().getContext("2d")
    @center = new app.Point(x: @width/2, y: @height/2)
    l(@ctx)

    @width = 960
    @height = 500
    @link_dist = 200
    @stroke_style = "#999999"
    @stroke_width = "4"
    @fill_style = "#darkslategray"
    @node_radius = 20
    @square_width = 20

    @force
      .nodes(@graph.nodes)
      .links(@graph.links)
      .size([@width, @height])
      .alpha(0.001)
      .linkDistance(@link_dist)
      .on("tick", @tick)
      .start()

  tick: () =>
    @ctx.clearRect(0, 0, @width, @height)
    @ctx.strokeStyle = @stroke_style
    @ctx.lineWidth = @stroke_width

    @graph.links.forEach (d) =>
      src = new app.Point(x: d.source.x, y: d.source.y)
      trg = new app.Point(x: d.target.x, y: d.target.y)

      # Check for edges going to the same node
      if not trg.equals(src)
        @draw_multinode_arc(src, trg)
      else
        @draw_singlenode_arc(src)

    # draw nodes
    @ctx.fillStyle = "darkslategray"
    @ctx.globalAlpha = ".4"
    @ctx.beginPath()

    @graph.nodes.forEach (d) =>
      @ctx.moveTo(d.x, d.y)

      if not d.hidden
        @ctx.arc(d.x, d.y, @node_radius, 0, 2 * Math.PI)
      # else
      #   @ctx.rect(d.x, d.y, @square_width, @square_width)

    @ctx.fill()

  ###
  # Draw arc between two different nodes, takes two Points and optionally the
  # nodes radius (r) and how far out the quads ctrl point goes out
  ###
  draw_multinode_arc: (src, trg, r=20, ctrl_r=40) ->
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

    @draw_quad_curve(src, ctrl, trg)
    @draw_quad_arrow(src, ctrl, trg)

    # @ctx.save()
    # @ctx.globalAlpha = "1"
    # @ctx.fillStyle = "red"
    # @ctx.fillRect(ctrl.x, ctrl.y, 7, 7)
    # @ctx.restore()

  draw_singlenode_arc: (src, r=40) ->
    @ctx.beginPath()
    vec = src.sub(@center).normalize().mul(r).add(src)
    # l(vec)
    @ctx.arc(vec.x, vec.y, r, 0, 2 * Math.PI)
    @ctx.stroke()

  draw_quad_arrow: (src, ctrl, trg) ->
    arrow_angle = Math.atan2(ctrl.x - trg.x, ctrl.y - trg.y) + Math.PI
    arrow_width = 15
    shift = Math.PI / 6

    @ctx.beginPath()
    ### Math from here: http://stackoverflow.com/questions/27778951/drawing-an-arrow-on-an-html5-canvas-quadratic-curve ###
    @ctx.moveTo(trg.x - (arrow_width * Math.sin(arrow_angle - shift)),
                  trg.y - (arrow_width * Math.cos(arrow_angle - shift)))
    @ctx.lineTo(trg.x, trg.y)
    @ctx.lineTo(trg.x - (arrow_width * Math.sin(arrow_angle + shift)),
                  trg.y - (arrow_width * Math.cos(arrow_angle + shift)))
    @ctx.stroke()

  ###
  # Abstraction around quadraticCurveTo using our Point object
  # draws from src to trg, using ctrl as the beizer control-point
  ###
  draw_quad_curve: (src, ctrl, trg) ->
    @ctx.beginPath()
    @ctx.moveTo(src.x, src.y)
    @ctx.quadraticCurveTo(ctrl.x, ctrl.y, trg.x, trg.y)
    @ctx.stroke()

 app.HMM = HMM
