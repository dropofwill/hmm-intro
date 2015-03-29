app = window.configApp()

###
# Object for persisting and manipulating absolute coordinates ('points') and
# relative coordinates ('vectors', e.g. pointB - pointA).
# The coordinate system is the same as for canvas (+y down, +x right)
# Angles are measured in radians with 0 pointing right
# Constructor:
# @x: x coord
# @y: y coord
# or
# @mag: vector magnitude, treated as positive
# @theta: vector angle relative to coord system
# inspired by Processing's vector implementation
###
class Point
  constructor: (opts) ->
    if opts.x? and opts.y?
      {@x, @y} = opts
      {@mag, @theta} = @get_polar(opts)
    else if opts.mag? and opts.theta?
      {@mag, @theta} = opts
      {@x, @y} = @get_cartesian(opts)
    else
      console.warn("Neither {x,y} or {mag, theta} pairs passed to constructor")

  ###
  # Immutable and chainable addition of two points
  # p1.add(p2) is p1 + p2
  ###
  add: (point) -> new Point(x: @x + point.x, y: @y + point.y)

  ###
  # Immutable and chainable subtraction of two points
  # p1.sub(p2) is p1 - p2
  ###
  sub: (point) -> new Point(x: @x - point.x, y: @y - point.y)

  ###
  # Immutable and chainable multiplication by a scalar
  ###
  mul: (scalar) -> new Point(x: @x * scalar, y: @y * scalar)

  ###
  # Immutable and chainable division by a scalar
  ###
  div: (scalar) ->
    if scalar isnt 0
      new Point(x: @x / scalar, y: @y / scalar)
    else
      console.warn("Can't divide by 0")
      this

  ###
  # Find the midpoint by halving the coords of a point
  ###
  midpoint: () -> @div(2)

  negate: () -> @mul(-1)

  ###
  # Return a clone of the current point
  ###
  clone: () -> new Point(x: @x, y: @y)

  ###
  # Checks whether the cartesian coordinates of a given point equal this one
  ###
  equals: (point) ->
    this is point or (@x is point.x and @y is point.y)

  dot: (point) ->

  cross: (point) ->

  project: (point) ->

  normalize: () ->
    if @mag isnt 0
      @div(@mag)
    else
      console.warn("Can't normalize 0 vector")
      this

  ###
  # Rotate about the x-axis or an optional center point
  ###
  rotate: (radians, center = false) ->
    cos = Math.cos(radians)
    sin = Math.sin(radians)
    point = if center then @sub(center) else this

    ### Apply 2d rotation matrix to get rotated x and y ###
    x = (cos * point.x) - (sin * point.y)
    y = (sin * point.x) + (cos * point.y)
    point = new Point(x: x, y: y)

    if center then point.add(center) else point

  ###
  # Given params {theta, mag} (in radians) return the {x, y}
  ###
  get_cartesian: (polar) ->
    x: Math.cos(polar.theta) * polar.mag
    y: -Math.sin(polar.theta) * polar.mag

  ###
  # Given params {x, y} return the {theta, mag} (in radians)
  ###
  get_polar: (cart) ->
    mag: @get_mag(cart)
    theta: Math.atan2(cart.x, cart.y)

  ###
  # Given params {x, y} return the magnitude using the Pythagorean theorem
  ###
  get_mag: (cart) ->
    Math.sqrt(cart.x * cart.x + cart.y * cart.y)

  ###
  # Given params {x, y} of another point return the distance from this point
  ###
  get_dist: (cart) ->
    Math.sqrt(Math.pow(@x - cart.x, 2)+ Math.pow(@y - cart.y, 2))


p1 = new Point(x: 1, y: 2)
p2 = new Point(mag: 10, theta: Math.PI/2)
l(p2)
l(p2.normalize())
# l(p1.add(p2))
# l(p1.sub(p2))
# l(p2.add(p2))
# l(p1.mul(10))
# l(p1.div(10))

### Attach Point object to the app object ###
app.Point = Point
