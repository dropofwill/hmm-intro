app = window.configApp()

app.example = undefined

window.onload = () ->
  d3.json "lib/data.json", (data) ->
    example_canvas = d3.select("body")
      .append("canvas")
        .attr("width", 960)
        .attr("height", 500)

    l('main', app)
    app.example = app.hmm()
    app.example(data, example_canvas)
