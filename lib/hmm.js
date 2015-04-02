(function() {
  var HMM, app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.configApp();


  /* exit if already defined */

  if (app.hmm != null) {
    l("app.hmm already defined");
    return;
  }


  /*
   * Closure for constructing an HMM model on arbitrary data
   */

  HMM = (function() {

    /*
     * The main initializer takes data, binding dom, and canvas element as input
     * D3 manipulates the state of this on callbacks to the DOM element,
     * This makes some of the way 'this' is handled confusing
     */
    function HMM(data, cvs, matrix, unique_id) {
      var ref, self;
      if (unique_id == null) {
        unique_id = 1;
      }
      this.balance_prob = bind(this.balance_prob, this);
      this.tick = bind(this.tick, this);
      this.setup_drag = bind(this.setup_drag, this);
      this.setup_mouse = bind(this.setup_mouse, this);
      this.setup_force = bind(this.setup_force, this);
      self = this;
      ref = [data, cvs, matrix, unique_id], this.graph = ref[0], this.canvas = ref[1], this.matrix_el = ref[2], this.uid = ref[3];
      this.size = this.graph.nodes.length;
      this.ctx = this.canvas.node().getContext("2d");
      this.width = cvs.node().width;
      this.height = cvs.node().height;
      this.center = new app.Point({
        x: this.width / 2,
        y: this.height / 2
      });
      this.link_dist = 200;
      this.node_radius = 20;
      this.force = d3.layout.force();
      this.drag = d3.behavior.drag();
      this.prob_scale = d3.scale.linear().domain([0.0, 1.0]).range([0.0, 10.0]);
      this.color_scale = d3.scale.category10();
      this.setup_force();
      this.setup_mouse();
      this.setup_drag();
      this.setup_matrix(this.matrix_el, this.force.nodes(), this.force.links());
      this.drag_node = void 0;
      this.transitioning = false;
      this.transition_percent = 0;
      this.current_node = this.select_initial_node();
      this.current_link;
      this.current_point;
    }


    /*
     * d3's implementation of a force layout handles all of the physics math
     * but doesn't do anything with the canvas
     */

    HMM.prototype.setup_force = function() {
      return this.force.nodes(this.graph.nodes).links(this.graph.links).size([this.width, this.height]).alpha(0.01).linkDistance(this.link_dist).on("tick", this.tick).start();
    };


    /*
     * Little bit of a dangerous optimization here
     * nodes are *not* points, but since they respond to #x/#y and that's all
     * we need for #get_dist this works in this case & saves on memory
     */

    HMM.prototype.setup_mouse = function() {
      var self;
      self = this;
      return this.canvas.on("mousemove", function() {
        var mouse;
        mouse = d3.mouse(this);
        mouse = new app.Point({
          x: mouse[0],
          y: mouse[1]
        });
        self.hover_node = void 0;
        return self.force.nodes().forEach(function(node) {
          var colliding;
          colliding = self.pt_circle_collide(mouse, node);
          if (colliding) {
            return self.hover_node = node;
          }
        });
      }).call(self.drag);
    };


    /*
     * Added the ability to aimlessly drag the graph around because Peter said it
     * wasn't fun enough
     */

    HMM.prototype.setup_drag = function() {
      var self;
      self = this;
      this.drag.on("dragstart", function() {
        return self.drag_node = self.hover_node;
      });
      this.drag.on("drag", function() {
        if (self.drag_node == null) {
          return;
        }
        self.drag_node.x = d3.event.x;
        self.drag_node.y = d3.event.y;
        return self.force.start();
      });
      return this.drag.on("dragend", function() {
        return self.drag_node = void 0;
      });
    };


    /*
     * The main drawing loop that animates the nodes and links
     */

    HMM.prototype.tick = function() {
      this.ctx.clearRect(0, 0, this.width, this.height);
      this.graph.links.forEach((function(_this) {
        return function(d) {
          return _this.draw_arc(d, {
            lineWidth: _this.prob_scale(d.prob)
          });
        };
      })(this));
      this.graph.nodes.forEach((function(_this) {
        return function(d) {
          return _this.draw_node(d);
        };
      })(this));
      return this.draw_state();
    };

    HMM.prototype.draw_state = function() {
      var tmp_pt;
      if (this.transitioning) {
        this.transition_percent += 2;
        if (this.current_link.ctrl != null) {
          tmp_pt = this.quad_xy_at_percent(this.current_link.source, this.current_link.ctrl, this.current_link.target, this.transition_percent);
        } else {
          this.transition_percent += 1;
          tmp_pt = this.cubic_xy_at_percent(this.current_link.source, this.current_link.ctrl1, this.current_link.ctrl2, this.current_link.source, this.transition_percent);
        }
        this.draw_node(tmp_pt, {
          radius: 30,
          alpha: 0.35,
          fillStyle: "gray"
        });
        this.force.resume();
        if (this.transition_percent >= 100) {
          this.transition_percent = 0;
          return this.transitioning = false;
        }
      } else {
        this.draw_node(this.current_node, {
          radius: 30,
          alpha: 0.35,
          fillStyle: "gray"
        });
        return this.force.resume();
      }
    };


    /*
     * Math for animating along a quad/cubic curve from http://bit.ly/1GHKvTe
     * See also: http://en.wikipedia.org/wiki/De_Casteljau's_algorithm
     * Takes the three points that define the curve, and a percent along it
     * either between 0 and 100
     */

    HMM.prototype.quad_xy_at_percent = function(src, ctrl, trg, percent) {
      var per, x, y;
      per = percent / 100;
      x = Math.pow(1 - per, 2) * src.x + 2 * (1 - per) * per * ctrl.x + Math.pow(per, 2) * trg.x;
      y = Math.pow(1 - per, 2) * src.y + 2 * (1 - per) * per * ctrl.y + Math.pow(per, 2) * trg.y;
      return new app.Point({
        x: x,
        y: y
      });
    };

    HMM.prototype.cubic_xy_at_percent = function(src, ctrl1, ctrl2, trg, percent) {
      var per, x, y;
      per = percent / 100;
      x = this.cubic_helper(per, src.x, ctrl1.x, ctrl2.x, trg.x);
      y = this.cubic_helper(per, src.y, ctrl1.y, ctrl2.y, trg.y);
      return new app.Point({
        x: x,
        y: y
      });
    };


    /*
     * Here be the math magic, but really returns the value of a cubic function
     * for a given set of parameters (a=src, b=ctrl1, c=ctrl2, d=trg) abreviated
     * for readability as a math function
     */

    HMM.prototype.cubic_helper = function(percent, a, b, c, d) {
      var t2, t3;
      t2 = percent * percent;
      t3 = t2 * percent;
      return a + (-a * 3 + percent * (3 * a - a * percent)) * percent + (3 * b + percent * (-6 * b + b * 3 * percent)) * percent + (c * 3 - c * 3 * percent) * t2 + d * t3;
    };


    /*
     * Randomly select a node to start with using an even distribution
     * Returns the actual node
     */

    HMM.prototype.select_initial_node = function() {
      var p;
      p = 1 / this.size;
      this.graph.nodes.forEach(function(n) {
        return n.prob = p;
      });
      return this.prob_random(this.graph.nodes);
    };

    HMM.prototype.select_next_node = function() {
      var links;
      links = this.get_links_from(this.current_node.index);
      this.transitioning = true;
      this.current_link = this.prob_random(links);
      return this.current_node = this.current_link.target;
    };


    /*
     * Takes a list of objects that respond to the prob_key with a float between
     * 0 and 1. Expects that these all sum to 1.
     * Returns a random object based on its distribution
     */

    HMM.prototype.prob_random = function(nodes, prob_key) {
      var last, rand, s;
      if (prob_key == null) {
        prob_key = "prob";
      }
      rand = Math.random();
      s = 0;
      last = nodes[nodes.length - 1];
      nodes.some(function(n) {
        s += n[prob_key];
        if (rand < s) {
          last = n;
          return true;
        }
      });
      return last;
    };


    /*
     * Collision detection for two points, the second of which has a default radius
     */

    HMM.prototype.pt_circle_collide = function(pt, circle_pt, radius) {
      if (radius == null) {
        radius = this.node_radius;
      }
      if (pt.get_dist(circle_pt) < radius) {
        return true;
      } else {
        return false;
      }
    };


    /*
     * Create the transition probability matrix and add it to the dom
     */

    HMM.prototype.setup_matrix = function(matrix_el, nodes, links) {
      var matrix, td, that, tr;
      that = this;
      matrix = this.matrix_data(_.clone(nodes), _.clone(links));
      tr = matrix_el.selectAll("tr").data(matrix).enter().append("tr");
      return td = tr.selectAll("td").data(Object).enter().append("td").each(function(d) {
        var el;
        el = d3.select(this);
        return that.build_cell(d, el);
      });
    };


    /*
     * sort by source to get the rows right
     * chunk by the size
     * then sort by target to get the columns right
     * pad the header row
     * create a first column and add the header row
     */

    HMM.prototype.matrix_data = function(nodes, links) {
      var padded_nodes, sort_matrix;
      this.size = nodes.length;
      padded_nodes = _(nodes).chain().unshift({}).value();
      return sort_matrix = _(links).chain().sortBy(function(l) {
        return l.source.index;
      }).chunk(this.size).map(function(row) {
        return _.sortBy(row, function(cell) {
          return cell.target.index;
        });
      }).map(function(row) {
        return _(row).chain().unshift(_.first(row).source).value();
      }).unshift(padded_nodes).value();
    };


    /*
     * Logic for determining which cell type to build
     */

    HMM.prototype.build_cell = function(d, el) {
      if ((d.prob != null)) {
        return this.build_inputs(d, el);
      } else {
        return this.build_headers(d, el);
      }
    };


    /*
     * Create the td's that require inputs for displaying the individual probs
     */

    HMM.prototype.build_inputs = function(d, el) {
      var num_attr, self;
      num_attr = {
        "class": "js-matrix-input",
        type: "number",
        min: 0,
        max: 1,
        step: 0.1
      };
      self = this;
      return el.style("background", (function(_this) {
        return function(d) {
          var c;
          c = d3.rgb(_this.color_scale(d.source.index));
          return _this.rgba(c.r, c.g, c.b, 0.6);
        };
      })(this)).append("input").attr(num_attr).attr("id", (function(_this) {
        return function(d) {
          return _this.set_link_uid(_this.uid, d.source.index, d.target.index);
        };
      })(this)).attr("value", function(d) {
        return d.prob;
      }).on("blur", function(d, i) {
        var cells, row_prob, v;
        if (v !== 0) {
          el = this;
          v = +el.value;
          d.prob = v;
          row_prob = [];
          cells = d3.select(el.parentElement.parentElement).selectAll("td > input").filter(function(d) {
            return el !== this;
          }).each(function(d) {
            return row_prob.push(d);
          }).call(function(d) {
            return self.balance_prob(row_prob, v);
          }).each(function(d) {
            return this.value = d.prob;
          });
          return self.tick();
        }
      });
    };


    /*
     * Create the td's that mark the row and columns
     */

    HMM.prototype.build_headers = function(d, el) {
      return el.text((function(_this) {
        return function(d) {
          return _this.num_to_alpha(d.index);
        };
      })(this)).style("background", (function(_this) {
        return function(d) {
          var c;
          if (d.index != null) {
            c = d3.rgb(_this.color_scale(d.index));
            return _this.rgba(c.r, c.g, c.b, 0.6);
          }
        };
      })(this));
    };


    /*
     * Sum the current probabilities and find the difference from 1
     * Find the what needs to subtracted to the other probs to equal 1
     * Sort from smallest to largest probability
     * Check if each individual is large enough to just subtract directly
     * If not set it to 0, and reset the even for the rest of them
     * Not fully tested, may be a bit brittle still
     */

    HMM.prototype.balance_prob = function(row_prob, val) {
      var count, diff, even, sum;
      sum = _.reduce(row_prob, (function(sum, d) {
        return sum + d.prob;
      }), val);
      diff = sum - 1;
      count = this.size - 1;
      even = diff / (this.size - 1);
      return _(row_prob).chain().sortBy(function(d) {
        return d.prob;
      }).forEach(function(d) {
        count--;
        if (d.prob > even) {
          return d.prob = d.prob - even;
        } else {
          diff = diff - d.prob;
          even = diff / count;
          return d.prob = 0;
        }
      }).sortBy(function(d) {
        return d.target.index;
      }).value();
    };


    /*
     * getter and setter for serializing link information into an HTML id
     */

    HMM.prototype.set_link_uid = function(uid, src_i, trg_i) {
      return "js-" + uid + "-" + src_i + "_" + trg_i;
    };

    HMM.prototype.get_link_uid = function(uid) {
      var arr, regex;
      regex = /js\-(\d+)\-(\d+)_(\d+)/g;
      arr = _.drop(regex.exec(uid), 1);
      return {
        uid: arr[0],
        src: arr[1],
        trg: arr[2]
      };
    };

    HMM.prototype.get_links = function(sub_node, index) {
      return this.graph.links.filter(function(l) {
        return l[sub_node].index === index;
      });
    };

    HMM.prototype.get_links_from = function(src_index) {
      return this.get_links("source", src_index);
    };

    HMM.prototype.get_links_to = function(trg_index) {
      return this.get_links("target", trg_index);
    };


    /*
     * Deal with floating point rounding errors loosely
     */

    HMM.prototype.strip = function(number) {
      return parseFloat(number.toPrecision(12));
    };


    /*
     * Convenience method for rgba with default alpha
     */

    HMM.prototype.rgba = function(r, g, b, a) {
      if (a == null) {
        a = 1;
      }
      return "rgba(" + r + ", " + g + ", " + b + ", " + a + ")";
    };


    /*
     * Return 0 indexed alphabet, ASCII for a is 97
     */

    HMM.prototype.num_to_alpha = function(n) {
      return String.fromCharCode(97 + n);
    };


    /*
     * Takes a link element and some ctx options
     * Draws an arc with an arrow
     */

    HMM.prototype.draw_arc = function(d, opts) {
      var ref, src, trg;
      if (opts == null) {
        opts = {};
      }
      this.ctx.save();
      this.ctx.strokeStyle = opts.strokeStyle != null ? opts.strokeStyle : opts.strokeStyle = this.color_scale(d.source.index);
      this.ctx.globalAlpha = opts.alpha != null ? opts.alpha : opts.alpha = 0.5;
      this.ctx.lineWidth = opts.lineWidth != null ? opts.lineWidth : opts.lineWidth = 0;
      src = new app.Point({
        x: d.source.x,
        y: d.source.y
      });
      trg = new app.Point({
        x: d.target.x,
        y: d.target.y
      });
      if (opts.lineWidth !== 0) {
        if (!trg.equals(src)) {
          d.ctrl = this.draw_multinode_arc(src, trg);
        } else {
          ref = this.draw_singlenode_arc(src), d.ctrl1 = ref[0], d.ctrl2 = ref[1];
        }
      }
      return this.ctx.restore();
    };


    /*
     * Takes a node element, some ctx options, and whether to draw the name
     * Draws a node with the nodes name
     */

    HMM.prototype.draw_node = function(d, opts) {
      var draw_text, radius;
      if (opts == null) {
        opts = {};
      }
      draw_text = opts.draw_text != null ? opts.draw_text : opts.draw_text = true;
      this.ctx.save();
      this.ctx.fillStyle = opts.fillStyle != null ? opts.fillStyle : opts.fillStyle = this.color_scale(d.index);
      this.ctx.globalAlpha = opts.alpha != null ? opts.alpha : opts.alpha = 1;
      radius = opts.radius != null ? opts.radius : opts.radius = this.node_radius;
      this.ctx.beginPath();
      this.ctx.moveTo(d.x, d.y);
      this.ctx.arc(d.x, d.y, radius, 0, 2 * Math.PI);
      this.ctx.fill();
      if (draw_text) {
        this.draw_text(this.num_to_alpha(d.index), d.x, d.y);
      }
      return this.ctx.restore();
    };

    HMM.prototype.draw_text = function(text, x, y, opts) {
      if (opts == null) {
        opts = {};
      }
      this.ctx.save();
      this.ctx.fillStyle = opts.fillStyle != null ? opts.fillStyle : opts.fillStyle = "#fff";
      this.ctx.font = opts.font != null ? opts.font : opts.font = "16px Merriweather Sans";
      this.ctx.textAlign = opts.textAlign != null ? opts.textAlign : opts.textAlign = "center";
      this.ctx.textBaseline = opts.textBaseline != null ? opts.textBaseline : opts.textBaseline = "middle";
      this.ctx.fillText(text, x, y);
      return this.ctx.restore();
    };


    /*
     * Draw arc between two different nodes, takes two Points and optionally the
     * nodes radius (r) and how far out the quads ctrl point goes out
     */

    HMM.prototype.draw_multinode_arc = function(src, trg, r, ctrl_r) {
      var ctrl, mid, vec;
      if (r == null) {
        r = 20;
      }
      if (ctrl_r == null) {
        ctrl_r = 40;
      }
      vec = trg.sub(src);

      /* Use relative vector between src and trg to get the angle
       * then expand to just a little bit larger than the nodes radius
       * then rotate around so that it is no longer at the center
       * finally convert the vector back to abs coordinates by adding trg
       */
      trg = vec.normalize().mul(r + 5).rotate(3 * Math.PI / 4).add(trg);
      mid = vec.midpoint();
      ctrl = new app.Point({
        theta: Math.PI + vec.theta,
        mag: ctrl_r
      }).add(src).add(mid);
      this.draw_quad_curve(src, ctrl, trg);
      this.draw_quad_arrow(src, ctrl, trg);
      return ctrl;
    };


    /*
     * Draw an arc to the same node using a cubic curve
     */

    HMM.prototype.draw_singlenode_arc = function(src, r) {
      var perp1, perp2, pos, pt, vec;
      if (r == null) {
        r = 70;
      }
      pt = new app.Point({
        x: src.x,
        y: src.y
      });
      pos = pt.sub(this.center).normalize();
      vec = pos.mul(r).add(pt);
      perp1 = new app.Point({
        x: pos.y,
        y: -pos.x
      }).mul(r * 1.5).add(vec);
      perp2 = new app.Point({
        x: -pos.y,
        y: pos.x
      }).mul(r * 1.5).add(vec);
      this.draw_cubic_curve(src, perp1, perp2, src);
      return [perp1, perp2];
    };


    /*
     * Draw a simple arrow along a quadratic curved path
     */

    HMM.prototype.draw_quad_arrow = function(src, ctrl, trg, opts) {
      var arrow_angle, arrow_width, shift;
      if (opts == null) {
        opts = {};
      }
      arrow_angle = Math.atan2(ctrl.x - trg.x, ctrl.y - trg.y) + Math.PI;
      arrow_width = 15;
      shift = Math.PI / 6;
      this.ctx.save();
      this.ctx.globalAlpha = 1;
      this.ctx.lineWidth = this.prob_scale(0.5);
      this.ctx.strokeStyle = opts.strokeStyle != null ? opts.strokeStyle : "#777";
      this.ctx.beginPath();

      /* Math from here: http://bit.ly/1IIDTDa */
      this.ctx.moveTo(trg.x - (arrow_width * Math.sin(arrow_angle - shift)), trg.y - (arrow_width * Math.cos(arrow_angle - shift)));
      this.ctx.lineTo(trg.x, trg.y);
      this.ctx.lineTo(trg.x - (arrow_width * Math.sin(arrow_angle + shift)), trg.y - (arrow_width * Math.cos(arrow_angle + shift)));
      this.ctx.stroke();
      return this.ctx.restore();
    };


    /*
     * Abstraction around bezierCurveTo using our Point object
     * draws from src to trg, using ctrl1, ctrl2 as the beizer control-points
     */

    HMM.prototype.draw_cubic_curve = function(src, ctrl1, ctrl2, trg) {
      this.ctx.beginPath();
      this.ctx.moveTo(src.x, src.y);
      this.ctx.bezierCurveTo(ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, trg.x, trg.y);
      return this.ctx.stroke();
    };


    /*
     * Abstraction around quadraticCurveTo using our Point object
     * draws from src to trg, using ctrl as the beizer control-point
     */

    HMM.prototype.draw_quad_curve = function(src, ctrl, trg) {
      this.ctx.beginPath();
      this.ctx.moveTo(src.x, src.y);
      this.ctx.quadraticCurveTo(ctrl.x, ctrl.y, trg.x, trg.y);
      return this.ctx.stroke();
    };

    return HMM;

  })();

  app.HMM = HMM;

}).call(this);

//# sourceMappingURL=hmm.js.map
