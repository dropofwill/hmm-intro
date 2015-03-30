app = window.configApp()

### exit if already defined ###
if app.hmm?
  l("app.hmm already defined")
  return

###
# Closure for constructing an HMM model on arbitrary data
###
class HMM

  ###
  # main initializer takes data, binding dom, and canvas element as input
  ###
  constructor: (data, bind, cvs) ->

    @width = cvs.node().width
    @height = cvs.node().height
    l(@width)
    @link_dist = 200
    @stroke_style = "#999999"
    @stroke_width = "4"
    @fill_style = "#darkslategray"
    @node_radius = 20
    @square_width = 20

    @force = d3.layout.force()
    @graph = data
    @bind = bind
    @canvas = cvs
    @ctx = @canvas.node().getContext("2d")
    @center = new app.Point(x: @width/2, y: @height/2)
    @prob_scale = d3.scale.linear().domain([0.0, 1.0]).range([0.0, 10.0])
    @color_scale = d3.scale.category10()

    @update(@graph)

    @force
      .nodes(@graph.nodes)
      .links(@graph.links)
      .size([@width, @height])
      .alpha(0.001)
      .linkDistance(@link_dist)
      .on("tick", @tick)
      .start()

  ###
  # The main drawing loop that animates the nodes and links
  ###
  tick: () =>
    @ctx.clearRect(0, 0, @width, @height)
    @ctx.strokeStyle = @stroke_style
    @ctx.lineWidth = @stroke_width

    @graph.links.forEach (d) =>
      @draw_arc(d, lineWidth: @prob_scale(d.prob))
    @graph.nodes.forEach (d) => @draw_node(d)


  update: (data) ->
    ### See http://bit.ly/1Hdyh30 for an explanation ###
    bind_nodes = @bind.selectAll("custom\\:node")
      .data(data.nodes)
      .call(@update_nodes)

    bind_links = @bind.selectAll("custom\\:links")
      .data(data.links)
      .call(@update_links)

  update_nodes: (selection) ->
    console.log(selection)
    selection.enter()
       .append("custom:node")
       .attr("x", (d) -> d.x)
       .attr("y", (d) -> d.y)

  update_links: (selection) ->
    console.log(selection)
    selection.enter()
       .append("custom:link")
       .attr("source", (d) -> d.source.x)
       .attr("y", (d) -> d.y)

  draw_arc: (d, opts={}) ->
    @ctx.save()
    @ctx.strokeStyle = opts.strokeStyle ?= @color_scale(d.source.index)
    @ctx.globalAlpha = opts.alpha       ?= 0.5
    @ctx.lineWidth   = opts.lineWidth   ?= 0

    src = new app.Point(x: d.source.x, y: d.source.y)
    trg = new app.Point(x: d.target.x, y: d.target.y)

    # Check for edges going to the same node
    if opts.lineWidth isnt 0
      if not trg.equals(src)
        @draw_multinode_arc(src, trg)
      else
        @draw_singlenode_arc(src)

    @ctx.restore()

  draw_node: (d, opts={}) ->
    @ctx.save()
    @ctx.fillStyle   = opts.fillStyle ?= @color_scale(d.index)
    @ctx.globalAlpha = opts.alpha     ?= 1
    @ctx.beginPath()
    @ctx.moveTo(d.x, d.y)

    if not d.hidden
      @ctx.arc(d.x, d.y, @node_radius, 0, 2 * Math.PI)

    @ctx.fill()
    @ctx.restore()

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

  draw_singlenode_arc: (src, r=40) ->
    @ctx.beginPath()
    vec = src.sub(@center).normalize().mul(r).add(src)
    @ctx.arc(vec.x, vec.y, r, 0, 2 * Math.PI)
    @ctx.stroke()

  draw_quad_arrow: (src, ctrl, trg, opts={}) ->
    arrow_angle = Math.atan2(ctrl.x - trg.x, ctrl.y - trg.y) + Math.PI
    arrow_width = 15
    shift = Math.PI / 6
    @ctx.save()
    @ctx.globalAlpha = 1
    @ctx.lineWidth   = @prob_scale(0.5)
    @ctx.strokeStyle = if opts.strokeStyle? then opts.strokeStyle else "#777"

    @ctx.beginPath()
    ### Math from here: http://bit.ly/1IIDTDa ###
    @ctx.moveTo(trg.x - (arrow_width * Math.sin(arrow_angle - shift)),
                trg.y - (arrow_width * Math.cos(arrow_angle - shift)))
    @ctx.lineTo(trg.x, trg.y)
    @ctx.lineTo(trg.x - (arrow_width * Math.sin(arrow_angle + shift)),
                trg.y - (arrow_width * Math.cos(arrow_angle + shift)))
    @ctx.stroke()
    @ctx.restore()

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
