app = window.configApp()

app.example = undefined
# Register the "custom" namespace prefix for our custom elements.
d3.ns.prefix.custom = "http://will-paul.com"

window.onload = () ->
  d3.json "lib/data.json", (data) ->
    canvas = d3.select("#js-mm-1")
      .append("canvas")
        .attr("width", 600)
        .attr("height", 600)

    l('main', app)
    app.example = new app.HMM(data, canvas)
