app = window.configApp()

app.example = undefined
# Register the "custom" namespace prefix for our custom elements.

window.onload = () ->
  d3.json "lib/data4.json", (data) ->
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
