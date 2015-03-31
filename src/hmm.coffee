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
  constructor: (data, cvs, matrix, unique_id=1) ->

    @width = cvs.node().width
    @height = cvs.node().height
    @uid = unique_id
    @link_dist = 200
    @node_radius = 20

    @force = d3.layout.force()
    @graph = data
    @canvas = cvs
    @matrix_el = matrix
    @ctx = @canvas.node().getContext("2d")
    @center = new app.Point(x: @width/2, y: @height/2)
    @prob_scale = d3.scale.linear().domain([0.0, 1.0]).range([0.0, 10.0])
    @color_scale = d3.scale.category10()
    @size = @graph.nodes.length

    @force
      .nodes(@graph.nodes)
      .links(@graph.links)
      .size([@width, @height])
      .alpha(0.001)
      .linkDistance(@link_dist)
      .on("tick", @tick)
      .start()

    @setup_matrix(@matrix_el, @force.nodes(), @force.links())

  ###
  # The main drawing loop that animates the nodes and links
  ###
  tick: () =>
    @ctx.clearRect(0, 0, @width, @height)

    @graph.links.forEach (d) =>
      @draw_arc(d, lineWidth: @prob_scale(d.prob))
    @graph.nodes.forEach (d) => @draw_node(d)

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
      .each(
        (d) ->
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

    sort_matrix = _(links).chain()
      .sortBy((l) -> l.source.index)
      .chunk(@size)
      .map((row) ->
        _.sortBy(row,
                (cell) -> cell.target.index))

    # Header row should have an empty first column
    padded_nodes = _(nodes).chain().unshift({}).value()

    # Add header and front row
    matrix = _(sort_matrix).chain()
      .map((row) ->
          _(row).chain()
            .unshift(_.first(row).source)
            .value())
      .unshift(padded_nodes)
      .value()

  build_cell: (d, el) ->
    self = this
    # Default attrs for number inputs
    num_attr =
      class: "js-matrix-input"
      type: "number"
      min: 0
      max: 1
      step: 0.1

    if (d.prob?)
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
              diff = v - d.prob
              row_prob = []
              l(diff)
              l(self.strip(0.3333 + 0.3333 + 0.3333))

              # tr > td * size > input, so find all the other inputs in the
              # row that aren't the changing element
              cells = d3.select(el.parentElement.parentElement)
                .selectAll("td > input")
                .each((d) -> row_prob.push(d))

              cells
                .filter((d) -> el isnt this)
                .each((d) ->
                  if d.prob > diff
                    d.prob = d.prob - diff
                  else
                    d.prob = 0
                    diff = diff - d.prob
                  l(this, d.prob)
                  this.value = d.prob)
              l(row_prob)
              self.tick())
    else
      el.text((d) => @num_to_alpha(d.index))
        .style("background", (d) =>
          if d.index?
            c = d3.rgb(@color_scale(d.index))
            @rgba(c.r, c.g, c.b, 0.6))

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
        @draw_multinode_arc(src, trg)
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

    if not d.hidden
      @ctx.beginPath()
      @ctx.moveTo(d.x, d.y)
      @ctx.arc(d.x, d.y, @node_radius, 0, 2 * Math.PI)
      @ctx.fill()

    if not d.hidden and draw_text
      @draw_text(@num_to_alpha(d.index), d.x, d.y)

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
