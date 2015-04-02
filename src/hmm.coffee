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
  # The main initializer takes data, binding dom, and canvas element as input
  # D3 manipulates the state of this on callbacks to the DOM element,
  # This makes some of the way 'this' is handled confusing
  ###
  constructor: (data, cvs, matrix, unique_id=1) ->
    self = this

    [@graph, @canvas, @matrix_el, @uid] = [data, cvs, matrix, unique_id]
    @size = @graph.nodes.length
    @ctx = @canvas.node().getContext("2d")

    @width = cvs.node().width
    @height = cvs.node().height
    @center = new app.Point(x: @width/2, y: @height/2)

    @link_dist = 200
    @node_radius = 20

    @force = d3.layout.force()
    @drag = d3.behavior.drag()
    @prob_scale = d3.scale.linear().domain([0.0, 1.0]).range([0.0, 10.0])
    @color_scale = d3.scale.category10()

    @setup_force()
    @setup_mouse()
    @setup_drag()
    @setup_matrix(@matrix_el, @force.nodes(), @force.links())

    @drag_node = undefined
    @transitioning = false
    @transition_percent = 0
    @current_node = @select_initial_node()
    @current_link
    @current_point #= new app.Point(x: @current_node.x, y: @current_node.y)

    # l(@get_links_from(@current_node.index))
    # @select_next_node()

  ###
  # d3's implementation of a force layout handles all of the physics math
  # but doesn't do anything with the canvas
  ###
  setup_force: () =>
    @force
      .nodes(@graph.nodes)
      .links(@graph.links)
      .size([@width, @height])
      .alpha(0.01)
      .linkDistance(@link_dist)
      .on("tick", @tick)
      .start()

  ###
  # Little bit of a dangerous optimization here
  # nodes are *not* points, but since they respond to #x/#y and that's all
  # we need for #get_dist this works in this case & saves on memory
  ###
  setup_mouse: () =>
    self = this
    @canvas.on("mousemove", () ->
      mouse = d3.mouse(this)
      mouse = new app.Point(x: mouse[0], y: mouse[1])
      self.hover_node = undefined

      self.force.nodes().forEach((node) ->
        colliding = self.pt_circle_collide(mouse, node)
        if colliding
          self.hover_node = node
      )
    ).call(self.drag)

  ###
  # Added the ability to aimlessly drag the graph around because Peter said it
  # wasn't fun enough
  ###
  setup_drag: () =>
    self = this
    @drag.on("dragstart", () -> self.drag_node = self.hover_node)

    @drag.on("drag", () ->
      if not self.drag_node?
        return
      self.drag_node.x = d3.event.x
      self.drag_node.y = d3.event.y
      self.force.start())

    @drag.on("dragend", () -> self.drag_node = undefined)

  ###
  # The main drawing loop that animates the nodes and links
  ###
  tick: () =>
    @ctx.clearRect(0, 0, @width, @height)

    @graph.links.forEach (d) => @draw_arc(d, lineWidth: @prob_scale(d.prob))
    @graph.nodes.forEach (d) => @draw_node(d)
    @draw_state()

  draw_state: () ->
    if @transitioning
      @transition_percent += 1

      if @current_link.ctrl?
        tmp_pt = @quad_xy_at_percent(@current_link.source, @current_link.ctrl,
                                     @current_link.target, @transition_percent)
      else
        src = @singlenode_arc_origin(@current_link.source)
        start_angle = src.sub(@current_node).theta
        l(start_angle * 180/Math.PI)
        tmp_pt = @circle_xy_at_percent(src, 40, @transition_percent, start_angle)

      @draw_node(tmp_pt, radius: 30, alpha: 0.35, fillStyle: "gray")
      @force.resume()

      if @transition_percent >= 100
        @transition_percent = 0
        @transitioning = false
    else
      @draw_node(@current_node, radius: 30, alpha: 0.35, fillStyle: "gray")
      @force.resume()

  ###
  # Math for animating along a quadratic curve from http://bit.ly/1GHKvTe
  # See also: http://en.wikipedia.org/wiki/De_Casteljau's_algorithm
  # Takes the three points that define the curve, and a percent along it
  # either between 0 and 100
  ###
  quad_xy_at_percent: (src, ctrl, trg, percent) ->
    per = percent / 100

    @ctx.save()
    @ctx.fillStyle = "black"
    @ctx.fillRect(src.x, src.y, 10, 10)
    @ctx.fillRect(ctrl.x, ctrl.y, 10, 10)
    @ctx.fillRect(trg.x, trg.y, 10, 10)
    @ctx.restore()

    x = Math.pow(1-per, 2) * src.x  +
        2 * (1-per) * per  * ctrl.x +
        Math.pow(per, 2)   * trg.x
    y = Math.pow(1-per, 2) * src.y  +
        2 * (1-per) * per  * ctrl.y +
        Math.pow(per, 2)   * trg.y
    return new app.Point(x: x, y: y)

  circle_xy_at_percent: (src, rad, percent, start_angle=0) ->
    angle = percent / 100 * (360 - start_angle) * (Math.PI / 180)
    x = src.x + rad * Math.cos(angle)
    y = src.y + rad * Math.sin(angle)
    return new app.Point(x: x, y: y)

  ###
  # Randomly select a node to start with using an even distribution
  # Returns the actual node
  ###
  select_initial_node: () ->
    p = 1/@size
    @graph.nodes.forEach((n) -> n.prob = p)
    @prob_random(@graph.nodes)

  select_next_node: () ->
    links = @get_links_from(@current_node.index)
    @transitioning = true
    @current_link = @prob_random(links)
    @current_node = @current_link.target

  ###
  # Takes a list of objects that respond to the prob_key with a float between
  # 0 and 1. Expects that these all sum to 1.
  # Returns a random object based on its distribution
  ###
  prob_random: (nodes, prob_key="prob") ->
    rand = Math.random()
    s = 0
    last = nodes[nodes.length - 1]

    nodes.some((n) ->
      s += n[prob_key]
      if rand < s
        last = n
        return true)

    return last

  ###
  # Collision detection for two points, the second of which has a default radius
  ###
  pt_circle_collide: (pt, circle_pt, radius=@node_radius) ->
    if pt.get_dist(circle_pt) < radius
      true
    else
      false

  ###
  # Create the transition probability matrix and add it to the dom
  ###
  setup_matrix: (matrix_el, nodes, links) ->
    that = this
    matrix = @matrix_data(_.clone(nodes), _.clone(links))

    tr = matrix_el.selectAll("tr")
      .data(matrix)
    .enter()
      .append("tr")

    td = tr.selectAll("td")
      .data(Object)
    .enter()
      .append("td")
      .each((d) ->
        el = d3.select(this)
        that.build_cell(d, el))

  ###
  # sort by source to get the rows right
  # chunk by the size
  # then sort by target to get the columns right
  # pad the header row
  # create a first column and add the header row
  ###
  matrix_data: (nodes, links) ->
    @size = nodes.length

    # Header row should have an empty first column
    padded_nodes = _(nodes).chain().unshift({}).value()

    sort_matrix = _(links).chain()
      # sort by source
      .sortBy((l) -> l.source.index)
      # convert the array into a nxn matrix
      .chunk(@size)
      # sort by target
      .map((row) ->
        _.sortBy(row, (cell) -> cell.target.index))
      # Add front column
      .map((row) ->
          _(row).chain()
            .unshift(_.first(row).source)
            .value())
      # Add header
      .unshift(padded_nodes)
      .value()

  ###
  # Logic for determining which cell type to build
  ###
  build_cell: (d, el) ->
    if (d.prob?)
      @build_inputs(d, el)
    else
      @build_headers(d, el)

  ###
  # Create the td's that require inputs for displaying the individual probs
  ###
  build_inputs: (d, el) ->
    # Default attrs for number inputs
    num_attr = {class:"js-matrix-input", type:"number", min:0, max:1, step:0.1}
    self = this

    el.style("background", (d) =>
        c = d3.rgb(@color_scale(d.source.index))
        @rgba(c.r, c.g, c.b, 0.6))
      .append("input")
        .attr(num_attr)
        .attr("id", (d) => @set_link_uid(@uid, d.source.index, d.target.index))
        .attr("value", (d) -> d.prob)
        .on("blur", (d, i) ->
          if v isnt 0
            el = this
            v = +el.value
            d.prob = v
            row_prob = []

            # tr > td * size > input, so find all the other inputs in the
            # row that aren't the changing element
            cells = d3.select(el.parentElement.parentElement)
              .selectAll("td > input")
              .filter((d) -> el isnt this)
              .each((d) -> row_prob.push(d))
              .call((d) -> self.balance_prob(row_prob, v))
              .each((d) -> this.value = d.prob)
            self.tick())

  ###
  # Create the td's that mark the row and columns
  ###
  build_headers: (d, el) ->
    el.text((d) => @num_to_alpha(d.index))
      .style("background", (d) =>
        if d.index?
          c = d3.rgb(@color_scale(d.index))
          @rgba(c.r, c.g, c.b, 0.6))

  ###
  # Sum the current probabilities and find the difference from 1
  # Find the what needs to subtracted to the other probs to equal 1
  # Sort from smallest to largest probability
  # Check if each individual is large enough to just subtract directly
  # If not set it to 0, and reset the even for the rest of them
  # Not fully tested, may be a bit brittle still
  ###
  balance_prob: (row_prob, val) =>
    sum = _.reduce(row_prob, ((sum, d) -> sum + d.prob), val)
    diff = sum - 1
    count = @size - 1
    even = diff / (@size - 1)

    _(row_prob).chain()
      .sortBy((d) -> d.prob)
      .forEach((d) ->
        count--
        if d.prob > even
          d.prob = d.prob - even
        else
          diff = diff - d.prob
          even = diff / count
          d.prob = 0
        )
       .sortBy((d) -> d.target.index)
       .value()

  ###
  # getter and setter for serializing link information into an HTML id
  ###
  set_link_uid: (uid, src_i, trg_i) ->
    "js-#{uid}-#{src_i}_#{trg_i}"

  get_link_uid: (uid) ->
    regex = /js\-(\d+)\-(\d+)_(\d+)/g
    arr = _.drop(regex.exec(uid), 1)

    uid: arr[0]
    src: arr[1]
    trg: arr[2]

  get_links: (sub_node, index) ->
    @graph.links.filter((l) -> l[sub_node].index is index)

  get_links_from: (src_index) ->
    @get_links("source", src_index)

  get_links_to: (trg_index) ->
    @get_links("target", trg_index)

  ###
  # Deal with floating point rounding errors loosely
  ###
  strip: (number) -> parseFloat(number.toPrecision(12))

  ###
  # Convenience method for rgba with default alpha
  ###
  rgba: (r, g, b, a=1) -> "rgba(#{r}, #{g}, #{b}, #{a})"

  ###
  # Return 0 indexed alphabet, ASCII for a is 97
  ###
  num_to_alpha: (n) -> String.fromCharCode(97 + n)

  ###
  # Takes a link element and some ctx options
  # Draws an arc with an arrow
  ###
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
        d.ctrl = @draw_multinode_arc(src, trg)
      else
        @draw_singlenode_arc(src)

    @ctx.restore()

  ###
  # Takes a node element, some ctx options, and whether to draw the name
  # Draws a node with the nodes name
  ###
  draw_node: (d, opts={}) ->
    draw_text        = opts.draw_text ?= true
    @ctx.save()
    @ctx.fillStyle   = opts.fillStyle ?= @color_scale(d.index)
    @ctx.globalAlpha = opts.alpha     ?= 1
    radius           = opts.radius    ?= @node_radius

    @ctx.beginPath()
    @ctx.moveTo(d.x, d.y)
    @ctx.arc(d.x, d.y, radius, 0, 2 * Math.PI)
    @ctx.fill()

    @draw_text(@num_to_alpha(d.index), d.x, d.y) if draw_text

    @ctx.restore()

  draw_text: (text, x, y, opts={}) ->
    @ctx.save()
    @ctx.fillStyle = opts.fillStyle ?= "#fff"
    @ctx.font      = opts.font      ?= "16px Merriweather Sans"
    @ctx.textAlign    = opts.textAlign    ?= "center"
    @ctx.textBaseline = opts.textBaseline ?= "middle"
    @ctx.fillText(text, x, y)
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
    return ctrl

  ###
  # Draw an arc to the same node
  ###
  draw_singlenode_arc: (src, r=40) ->
    @ctx.beginPath()
    vec = @singlenode_arc_origin(src, r)
    @ctx.arc(vec.x, vec.y, r, 0, 2 * Math.PI)
    @ctx.stroke()

  singlenode_arc_origin: (src, r=40) ->
    pt = new app.Point(x: src.x, y: src.y)
    vec = pt.sub(@center).normalize().mul(r).add(pt)

  ###
  # Draw a simple arrow along a quadratic curved path
  ###
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
