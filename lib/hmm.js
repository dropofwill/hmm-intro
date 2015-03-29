(function() {
  var HMM, app,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  app = window.configApp();


  /* exit if already defined */

  if (app.hmm != null) {
    l("app.hmm already defined");
    return;
  }

  HMM = (function() {
    function HMM(d, el) {
      this.tick = bind(this.tick, this);
      this.force = d3.layout.force();
      this.graph = d;
      this.canvas = el;
      this.ctx = this.canvas.node().getContext("2d");
      this.center = new app.Point({
        x: this.width / 2,
        y: this.height / 2
      });
      l(this.ctx);
      this.width = 960;
      this.height = 500;
      this.link_dist = 200;
      this.stroke_style = "#999999";
      this.stroke_width = "4";
      this.fill_style = "#darkslategray";
      this.node_radius = 20;
      this.square_width = 20;
      this.force.nodes(this.graph.nodes).links(this.graph.links).size([this.width, this.height]).alpha(0.001).linkDistance(this.link_dist).on("tick", this.tick).start();
    }

    HMM.prototype.tick = function() {
      this.ctx.clearRect(0, 0, this.width, this.height);
      this.ctx.strokeStyle = this.stroke_style;
      this.ctx.lineWidth = this.stroke_width;
      this.graph.links.forEach((function(_this) {
        return function(d) {
          var src, trg;
          src = new app.Point({
            x: d.source.x,
            y: d.source.y
          });
          trg = new app.Point({
            x: d.target.x,
            y: d.target.y
          });
          if (!trg.equals(src)) {
            return _this.draw_multinode_arc(src, trg);
          } else {
            return _this.draw_singlenode_arc(src);
          }
        };
      })(this));
      this.ctx.fillStyle = "darkslategray";
      this.ctx.globalAlpha = ".4";
      this.ctx.beginPath();
      this.graph.nodes.forEach((function(_this) {
        return function(d) {
          _this.ctx.moveTo(d.x, d.y);
          if (!d.hidden) {
            return _this.ctx.arc(d.x, d.y, _this.node_radius, 0, 2 * Math.PI);
          }
        };
      })(this));
      return this.ctx.fill();
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

    HMM.prototype.draw_quad_arrow = function(src, ctrl, trg) {
      var arrow_angle, arrow_width, shift;
      arrow_angle = Math.atan2(ctrl.x - trg.x, ctrl.y - trg.y) + Math.PI;
      arrow_width = 15;
      shift = Math.PI / 6;
      this.ctx.beginPath();

      /* Math from here: http://stackoverflow.com/questions/27778951/drawing-an-arrow-on-an-html5-canvas-quadratic-curve */
      this.ctx.moveTo(trg.x - (arrow_width * Math.sin(arrow_angle - shift)), trg.y - (arrow_width * Math.cos(arrow_angle - shift)));
      this.ctx.lineTo(trg.x, trg.y);
      this.ctx.lineTo(trg.x - (arrow_width * Math.sin(arrow_angle + shift)), trg.y - (arrow_width * Math.cos(arrow_angle + shift)));
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
