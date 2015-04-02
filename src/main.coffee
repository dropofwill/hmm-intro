app = window.configApp()

app.example = undefined
# Register the "custom" namespace prefix for our custom elements.

window.onload = () ->
  self = this
  number_nodes = 3
  max_nodes = 8
  min_nodes = 1
  data = generate_data(number_nodes)
  width = 500
  height = 450
  canvas = d3.select("#js-mm-1")
    .append("canvas")
      .attr("width", width)
      .attr("height", height)

  matrix_el = d3.select("#js-mm-matrix-1")
    .insert("table", ":first-child")

  app.example = new app.HMM(data, canvas, matrix_el, 1)

  next_el = d3.select("#js-mm-next-1")
    .on("click", () -> app.example.select_next_node())

  plus_el = d3.select("#js-mm-plus-1")
    .on("click", () ->
      number_nodes += 1 if number_nodes < max_nodes
      data = generate_data(number_nodes)

      delete_children(matrix_el.node())
      app.example = null
      app.example = new app.HMM(data, canvas, matrix_el, 1))




###
# Generate an even probability ergodic (fully-connected) data set
###
generate_data = (number_nodes) ->
  data = {}
  even_prob = 1/number_nodes
  [sx, sy] = [500, 300]
  data.nodes = _.times(number_nodes, (n) -> x: sx + n*10, y: sy + n*10)
  data.links = _.flatten(
                _.times(number_nodes, (n) ->
                    _.times(number_nodes, (m) ->
                       source: n, target: m, prob: even_prob)))
  return data

delete_children = (node) ->
  while node.firstChild
    node.removeChild(node.firstChild)
