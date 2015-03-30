app = window.configApp()

app.example = undefined
# Register the "custom" namespace prefix for our custom elements.
d3.ns.prefix.custom = "http://will-paul.com"

window.onload = () ->
  d3.json "lib/data.json", (data) ->
    canvas = d3.select("body")
      .append("canvas")
        .attr("width", 960)
        .attr("height", 500)

    bind = d3.select("body")
      .append("custom:sketch")
        .attr("width", 900)
        .attr("height", 500)

    l('main', app)
    app.example = new app.HMM(data, bind, canvas)
