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
  constructor: (opts, fromAngle=false) ->
    if not fromAngle
      {@x, @y} = opts
      {@mag, @theta} = @get_polar(opts)
    else
      {@mag, @theta} = opts
      {@x, @y} = @get_cartesian(opts)

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
  div: (scalar) -> new Point(x: @x / scalar, y: @y / scalar)

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

  normalize: (len = 1) ->
    current = @get_mag(x: @x, y: @y)
    scale = if current isnt 0 then len / current else 0

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

  get_dist: (cart1, cart2) ->
    Math.sqrt(Math.pow(cart1.x - cart2.x, 2)+ Math.pow(cart1.y - cart2.y, 2))


p1 = new Point(x: 1, y: 2)
p2 = new Point(mag: 10, theta: Math.PI/2, true)
l(p2)
# l(p1.add(p2))
# l(p1.sub(p2))
# l(p2.add(p2))
# l(p1.mul(10))
# l(p1.div(10))

### Attach Point object to the app object ###
app.Point = Point
