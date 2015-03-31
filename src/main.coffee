app = window.configApp()

app.example = undefined
# Register the "custom" namespace prefix for our custom elements.

window.onload = () ->
  d3.json "lib/data4.json", (data) ->
    dim = 500
    canvas = d3.select("#js-mm-1")
      .append("canvas")
        .attr("width", dim)
        .attr("height", dim)

    matrix_el = d3.select("#js-mm-matrix-1")
      .append("table")

    l('main', app)
    app.example = new app.HMM(data, canvas, matrix_el, 1)
