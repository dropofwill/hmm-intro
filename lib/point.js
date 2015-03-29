(function() {
  var Point, app, p1, p2;

  app = window.configApp();


  /*
   * Object for persisting and manipulating absolute coordinates ('points') and
   * relative coordinates ('vectors', e.g. pointB - pointA).
   * The coordinate system is the same as for canvas (+y down, +x right)
   * Angles are measured in radians with 0 pointing right
   * Constructor:
   * @x: x coord
   * @y: y coord
   * or
   * @mag: vector magnitude, treated as positive
   * @theta: vector angle relative to coord system
   * inspired by Processing's vector implementation
   */

  Point = (function() {
    function Point(opts, fromAngle) {
      var ref, ref1;
      if (fromAngle == null) {
        fromAngle = false;
      }
      if (!fromAngle) {
        this.x = opts.x, this.y = opts.y;
        ref = this.get_polar(opts), this.mag = ref.mag, this.theta = ref.theta;
      } else {
        this.mag = opts.mag, this.theta = opts.theta;
        ref1 = this.get_cartesian(opts), this.x = ref1.x, this.y = ref1.y;
      }
    }


    /*
     * Immutable and chainable addition of two points
     * p1.add(p2) is p1 + p2
     */

    Point.prototype.add = function(point) {
      return new Point({
        x: this.x + point.x,
        y: this.y + point.y
      });
    };


    /*
     * Immutable and chainable subtraction of two points
     * p1.sub(p2) is p1 - p2
     */

    Point.prototype.sub = function(point) {
      return new Point({
        x: this.x - point.x,
        y: this.y - point.y
      });
    };


    /*
     * Immutable and chainable multiplication by a scalar
     */

    Point.prototype.mul = function(scalar) {
      return new Point({
        x: this.x * scalar,
        y: this.y * scalar
      });
    };


    /*
     * Immutable and chainable division by a scalar
     */

    Point.prototype.div = function(scalar) {
      return new Point({
        x: this.x / scalar,
        y: this.y / scalar
      });
    };


    /*
     * Find the midpoint by halving the coords of a point
     */

    Point.prototype.midpoint = function() {
      return this.div(2);
    };

    Point.prototype.negate = function() {
      return this.mul(-1);
    };


    /*
     * Return a clone of the current point
     */

    Point.prototype.clone = function() {
      return new Point({
        x: this.x,
        y: this.y
      });
    };


    /*
     * Checks whether the cartesian coordinates of a given point equal this one
     */

    Point.prototype.equals = function(point) {
      return this === point || (this.x === point.x && this.y === point.y);
    };

    Point.prototype.dot = function(point) {};

    Point.prototype.cross = function(point) {};

    Point.prototype.project = function(point) {};

    Point.prototype.normalize = function(len) {
      var current, scale;
      if (len == null) {
        len = 1;
      }
      current = this.get_mag({
        x: this.x,
        y: this.y
      });
      return scale = current !== 0 ? len / current : 0;
    };


    /*
     * Rotate about the x-axis or an optional center point
     */

    Point.prototype.rotate = function(radians, center) {
      var cos, point, sin, x, y;
      if (center == null) {
        center = false;
      }
      cos = Math.cos(radians);
      sin = Math.sin(radians);
      point = center ? this.sub(center) : this;

      /* Apply 2d rotation matrix to get rotated x and y */
      x = (cos * point.x) - (sin * point.y);
      y = (sin * point.x) + (cos * point.y);
      point = new Point({
        x: x,
        y: y
      });
      if (center) {
        return point.add(center);
      } else {
        return point;
      }
    };


    /*
     * Given params {theta, mag} (in radians) return the {x, y}
     */

    Point.prototype.get_cartesian = function(polar) {
      return {
        x: Math.cos(polar.theta) * polar.mag,
        y: -Math.sin(polar.theta) * polar.mag
      };
    };


    /*
     * Given params {x, y} return the {theta, mag} (in radians)
     */

    Point.prototype.get_polar = function(cart) {
      return {
        mag: this.get_mag(cart),
        theta: Math.atan2(cart.x, cart.y)
      };
    };


    /*
     * Given params {x, y} return the magnitude using the Pythagorean theorem
     */

    Point.prototype.get_mag = function(cart) {
      return Math.sqrt(cart.x * cart.x + cart.y * cart.y);
    };


    /*
     * Given params {x, y} of another point return the distance from this point
     */

    Point.prototype.get_dist = function(cart) {
      return Math.sqrt(Math.pow(this.x - cart.x, 2) + Math.pow(this.y - cart.y, 2));
    };

    return Point;

  })();

  p1 = new Point({
    x: 1,
    y: 2
  });

  p2 = new Point({
    mag: 10,
    theta: Math.PI / 2
  }, true);

  l(p2);


  /* Attach Point object to the app object */

  app.Point = Point;

}).call(this);

//# sourceMappingURL=point.js.map
