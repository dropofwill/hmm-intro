app = window.configApp()

app.example = undefined

window.onload = () ->
  d3.json "lib/data5.json", (data) ->
    example_canvas = d3.select("body")
      .append("canvas")
        .attr("width", 960)
        .attr("height", 500)

    l('main', app)
    app.example = new app.HMM(data, example_canvas)
