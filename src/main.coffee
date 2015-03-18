DEBUG = true

l = (vals...) ->
  vals.forEach (v) ->
    console.log(v) if DEBUG

app = app || {}
app.example1 = undefined

window.onload = () ->
  d3.json "lib/data.json", (data) ->
    a_canvas = d3.select("body").append("canvas")
      .attr("width", 960)
      .attr("height", 500)

    app.example1 = app.hmm()
    app.example1(data, a_canvas)
