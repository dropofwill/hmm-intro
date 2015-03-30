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
     * main initializer takes data, binding dom, and canvas element as input
     */
    function HMM(data, cvs, matrix) {
      this.tick = bind(this.tick, this);
      this.width = cvs.node().width;
      this.height = cvs.node().height;
      this.link_dist = 200;
      this.stroke_style = "#999999";
      this.stroke_width = "4";
      this.fill_style = "#darkslategray";
      this.node_radius = 20;
      this.square_width = 20;
      this.force = d3.layout.force();
      this.graph = data;
      this.canvas = cvs;
      this.matrix_el = matrix;
      this.ctx = this.canvas.node().getContext("2d");
      this.center = new app.Point({
        x: this.width / 2,
        y: this.height / 2
      });
      this.prob_scale = d3.scale.linear().domain([0.0, 1.0]).range([0.0, 10.0]);
      this.color_scale = d3.scale.category10();
      this.force.nodes(this.graph.nodes).links(this.graph.links).size([this.width, this.height]).alpha(0.001).linkDistance(this.link_dist).on("tick", this.tick).start();
      this.setup_matrix(this.matrix_el, this.force.nodes(), this.force.links());
    }


    /*
     * The main drawing loop that animates the nodes and links
     */

    HMM.prototype.tick = function() {
      this.ctx.clearRect(0, 0, this.width, this.height);
      this.ctx.strokeStyle = this.stroke_style;
      this.ctx.lineWidth = this.stroke_width;
      this.graph.links.forEach((function(_this) {
        return function(d) {
          return _this.draw_arc(d, {
            lineWidth: _this.prob_scale(d.prob)
          });
        };
      })(this));
      return this.graph.nodes.forEach((function(_this) {
        return function(d) {
          return _this.draw_node(d);
        };
      })(this));
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
      var matrix, padded_nodes, size, sort_matrix;
      size = nodes.length;
      sort_matrix = _(links).chain().sortBy(function(l) {
        return l.source.index;
      }).chunk(size).map(function(row) {
        return _.sortBy(row, function(cell) {
          return cell.target.index;
        });
      });
      padded_nodes = _(nodes).chain().unshift({}).value();
      return matrix = _(sort_matrix).chain().map(function(row) {
        return _(row).chain().unshift(_.first(row).source).value();
      }).unshift(padded_nodes).value();
    };

    HMM.prototype.build_cell = function(d, el) {
      if ((d.prob != null)) {
        return el.style("background", (function(_this) {
          return function(d) {
            var c;
            c = d3.rgb(_this.color_scale(d.source.index));
            return _this.rgba(c.r, c.g, c.b, 0.5);
          };
        })(this)).append("input").attr({
          type: "number",
          min: 0,
          max: 1,
          step: 0.1,
          arrows: true
        }).attr("value", function(d) {
          return d.prob;
        });
      } else {
        return el.text(function(d) {
          return d.index;
        }).style("background", (function(_this) {
          return function(d) {
            var c;
            if (d.index != null) {
              c = d3.rgb(_this.color_scale(d.index));
              return _this.rgba(c.r, c.g, c.b, 0.5);
            }
          };
        })(this));
      }
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

    num_to_alpha(function(n) {
      return String.fromCharCode(97 + n);
    });

    HMM.prototype.update = function(data) {

      /* See http://bit.ly/1Hdyh30 for an explanation */
      var bind_links, bind_nodes;
      bind_nodes = this.bind.selectAll("custom\\:node").data(data.nodes).call(this.update_nodes);
      return bind_links = this.bind.selectAll("custom\\:links").data(data.links).call(this.update_links);
    };

    HMM.prototype.update_nodes = function(selection) {
      return selection.enter().append("custom:node").attr("x", function(d) {
        return d.x;
      }).attr("y", function(d) {
        return d.y;
      });
    };

    HMM.prototype.update_links = function(selection) {
      return selection.enter().append("custom:link").attr("source", function(d) {
        return d.source.x;
      }).attr("y", function(d) {
        return d.y;
      });
    };

    HMM.prototype.draw_arc = function(d, opts) {
      var src, trg;
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
          this.draw_multinode_arc(src, trg);
        } else {
          this.draw_singlenode_arc(src);
        }
      }
      return this.ctx.restore();
    };

    HMM.prototype.draw_node = function(d, opts) {
      if (opts == null) {
        opts = {};
      }
      this.ctx.save();
      this.ctx.fillStyle = opts.fillStyle != null ? opts.fillStyle : opts.fillStyle = this.color_scale(d.index);
      this.ctx.globalAlpha = opts.alpha != null ? opts.alpha : opts.alpha = 1;
      this.ctx.beginPath();
      this.ctx.moveTo(d.x, d.y);
      if (!d.hidden) {
        this.ctx.arc(d.x, d.y, this.node_radius, 0, 2 * Math.PI);
      }
      this.ctx.fill();
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
      return this.draw_quad_arrow(src, ctrl, trg);
    };

    HMM.prototype.draw_singlenode_arc = function(src, r) {
      var vec;
      if (r == null) {
        r = 40;
      }
      this.ctx.beginPath();
      vec = src.sub(this.center).normalize().mul(r).add(src);
      this.ctx.arc(vec.x, vec.y, r, 0, 2 * Math.PI);
      return this.ctx.stroke();
    };

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
