// Generated by CoffeeScript 1.3.3
(function() {
  var BarChart, GeoChart, HexChart, HexContainer, barChart, container, drgs, first, geoChart, renderContainer, renderMap, second, storeDrgs,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  HexContainer = (function() {

    function HexContainer(div) {
      this.div = div;
      this.margin = {
        top: 5,
        bottom: 0,
        left: 30,
        right: 20
      };
      this.width = 990 - this.margin.left - this.margin.right;
      this.height = 140 - this.margin.top - this.margin.bottom;
      this.meanPayments = null;
      this.meanCharges = null;
      this.svg = d3.select(this.div).append("svg").attr("width", this.width + this.margin.left + this.margin.right).attr("height", this.height + this.margin.top + this.margin.bottom).append("g").attr("transform", "translate(" + this.margin.left + "," + this.margin.top + ")");
    }

    return HexContainer;

  })();

  HexChart = (function() {

    function HexChart(data, geo, container, indicator, yPosition) {
      this.data = data;
      this.geo = geo;
      this.container = container;
      this.indicator = indicator;
      this.yPosition = yPosition;
      this.xIndicator = __bind(this.xIndicator, this);

      this.brushMove = __bind(this.brushMove, this);

      this.width = this.container.width - 300;
      this.height = this.container.height;
      this.color = d3.scale.linear().range(["white", "red"]).interpolate(d3.interpolateLab);
      this.xScale = d3.scale.linear().range([0, this.width]);
      this.hexHeight = 25;
      this.hexRadius = 2;
      this.yScale = d3.scale.linear().range([this.hexHeight, 1]).domain([this.hexHeight, 1]);
      this.xAxis = d3.svg.axis().scale(this.xScale).ticks(7).tickSize(10).tickPadding("4").orient("bottom");
      this.hexbin = d3.hexbin().size([this.width, this.hexHeight]).radius(this.hexRadius);
      this.brush = d3.svg.brush().x(this.xScale).on("brush", this.brushMove);
      this.precisionFormat = d3.format(".2f");
      this.svg = this.container.svg.append("g").attr("transform", "translate(" + 0 + "," + this.yPosition + ")");
      this.svg.append("clipPath").attr("id", "clip").append("rect").attr("class", "mesh").attr("width", this.width).attr("height", this.hexHeight);
      this.svg.append("text").attr('x', this.width + 10).attr('y', 25).text(this.capitalize(this.indicator));
    }

    HexChart.prototype.renderComparison = function() {
      var percentage;
      percentage = this.precisionFormat((this.container.meanPayments / this.container.meanCharges) * 100) + "%";
      d3.select(".progress-bar").style("width", percentage);
      return d3.select("#difference-ratio").text(percentage);
    };

    HexChart.prototype.brushMove = function() {
      var e, selected;
      e = d3.event.target.extent();
      selected = [];
      if (e[0] === e[1]) {
        return this.geo.renderSelected(this.data, this.indicator, this.xScale.invert(0), this.xScale.invert(this.width));
      } else {
        this.data.forEach(function(d) {
          if (e[0] <= d.x && d.x <= e[1]) {
            return selected.push(d);
          }
        });
        return this.geo.renderSelected(selected, this.indicator, e[0], e[1]);
      }
    };

    HexChart.prototype.capitalize = function(str) {
      return str.charAt(0).toUpperCase() + str.substring(1).toLowerCase();
    };

    HexChart.prototype.xIndicator = function(d) {
      if (this.indicator === 'payments') {
        return d.avg_total_payments;
      } else {
        return d.avg_covered_charges;
      }
    };

    HexChart.prototype.render = function() {
      var points,
        _this = this;
      if (this.indicator === 'charges') {
        this.renderComparison();
      }
      points = [];
      this.xScale.domain(d3.extent(this.data, this.xIndicator)).nice();
      this.xAxis.scale(this.xScale);
      this.data.forEach(function(d, i) {
        d.x = _this.xIndicator(d);
        d.y = 1;
        return _.range(1, 43, 3).forEach(function(y) {
          return points.push([_this.xScale(d.x), _this.yScale(y)]);
        });
      });
      this.color.domain([
        0, d3.max(this.hexbin(points), function(d) {
          return d.length * 0.5;
        })
      ]);
      this.svg.select("g.x.axis").remove();
      this.svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + this.hexHeight + ")").call(this.xAxis);
      if (this.hexagons) {
        this.hexagons.remove();
      }
      this.hexagons = this.svg.append("g").attr("clip-path", "url(#clip)").selectAll(".hexagon").data(this.hexbin(points)).enter().append("path").attr("class", "hexagon").attr("d", this.hexbin.hexagon()).attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
      }).style("fill", function(d) {
        return _this.color(d.length);
      });
      return this.svg.append("g").attr("class", "brush").call(this.brush).selectAll("rect").attr("y", 0).attr("height", this.hexHeight);
    };

    return HexChart;

  })();

  GeoChart = (function() {

    function GeoChart(topology, div, barChart) {
      this.topology = topology;
      this.div = div;
      this.barChart = barChart;
      this.renderSelected = __bind(this.renderSelected, this);

      this.mouseUp = __bind(this.mouseUp, this);

      this.handleClick = __bind(this.handleClick, this);

      this.mouseDown = __bind(this.mouseDown, this);

      this.findSimilar = __bind(this.findSimilar, this);

      this.tooltipText = __bind(this.tooltipText, this);

      this.margin = {
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
      };
      this.providers = [];
      this.width = 900 - this.margin.left - this.margin.right;
      this.height = 540 - this.margin.top - this.margin.bottom;
      this.projection = d3.geo.albersUsa().scale(1100).translate([480, 270]);
      this.path = d3.geo.path().projection(this.projection);
      this.precisionFormat = d3.format(".2f");
      this.states = [];
      this.circles = [];
      this.selected = {
        charges: [],
        payments: []
      };
      this.color = d3.scale.quantize().range(colorbrewer.Reds[9]);
      this.svg = d3.select(this.div).append("svg").attr("width", this.width + this.margin.left + this.margin.right).attr("height", this.height + this.margin.top + this.margin.bottom).append("g").attr("transform", "translate(" + this.margin.left + "," + this.margin.top + ")");
    }

    GeoChart.prototype.render = function() {
      var geometries;
      geometries = topojson.object(this.topology, this.topology.objects.states).geometries.filter(function(d) {
        return d.properties.code !== 'VI' && d.properties.code !== 'PR';
      });
      this.states = this.svg.selectAll("path").data(geometries).enter().append("path").attr("d", this.path);
      return this.renderProviders;
    };

    GeoChart.prototype.attachTooltips = function() {
      return $("circle").tooltip({
        position: {
          my: "left+15 center",
          at: "top center"
        },
        show: true
      });
    };

    GeoChart.prototype.tooltipText = function(d) {
      return d.provider.name + "<br/>" + d.provider.city + ", " + d.provider.state_code + "<br/>Avg payments: $" + this.precisionFormat(d.avg_total_payments) + "<br/>Avg Charges: $" + this.precisionFormat(d.avg_covered_charges) + "<br/>Total Discharges: " + d.total_discharges;
    };

    GeoChart.prototype.findSimilar = function(selected) {
      var threshold;
      threshold = 10.0;
      return this.svg.selectAll("circle.shown").each(function(d) {
        var circle;
        circle = d3.select(this);
        if (Math.abs(d.avg_total_payments - selected.avg_total_payments) < threshold) {
          return circle.attr("r", 10);
        } else {
          return circle.attr("r", 0);
        }
      });
    };

    GeoChart.prototype.mouseDown = function(d) {
      var selected;
      selected = d3.select(d3.event.target);
      this.findSimilar(d);
      return selected.attr("r", 10);
    };

    GeoChart.prototype.handleClick = function(d) {
      var that, url;
      url = "/providers/" + d.provider_id;
      that = this;
      return d3.json(url, function(error, data) {
        return that.barChart.render(data);
      });
    };

    GeoChart.prototype.mouseUp = function(d) {
      var selected;
      selected = d3.select(d3.event.target);
      selected.attr("r", 4);
      return this.svg.selectAll("circle.shown").each(function(d) {
        return d3.select(this).attr("r", 4);
      });
    };

    GeoChart.prototype.updateLabels = function(indicator, left, right) {
      var selector;
      selector = "#" + indicator;
      d3.select(selector + "-left").text(left);
      return d3.select(selector + "-right").text(right);
    };

    GeoChart.prototype.renderSelected = function(providers, bucket, left, right) {
      var ids, intersection, leftText, other, otherAttr, rightText, sorted;
      ids = _.pluck(providers, 'provider_id');
      otherAttr = bucket === 'charges' ? 'payments' : 'charges';
      other = this.selected[otherAttr];
      if (ids.length !== this.selected[bucket].length) {
        this.selected[bucket] = ids;
        intersection = _.intersection(ids, other);
        d3.select("#provider-count").text(intersection.length);
        leftText = "$" + Math.floor(left);
        rightText = "$" + Math.floor(right);
        this.updateLabels(bucket, leftText, rightText);
        this.svg.selectAll("circle").each(function(d) {
          if (_.contains(intersection, d.provider_id)) {
            return d3.select(this).attr("r", 4).classed("shown", true);
          } else {
            return d3.select(this).attr("r", 0).classed("shown", false);
          }
        });
        sorted = _.filter(this.providers, function(p) {
          return _.contains(intersection, p.provider_id);
        });
        sorted = _.sortBy(sorted, function(provider) {
          return provider.avg_covered_charges;
        });
        return this.updateList(sorted);
      }
    };

    GeoChart.prototype.updateList = function(sorted) {
      var cheapest, expensive, s, size;
      size = sorted.length;
      cheapest = sorted.slice(0, 5);
      expensive = sorted.slice(size - 5, size);
      s = "<tr>              <td>index</td>              <td>name</td>            </tr>";
      $("#least-expensive tbody").html('');
      cheapest.forEach(function(p, i) {
        var tr;
        tr = s.replace("name", p.provider.name + " (" + p.provider.city + ", " + p.provider.state_code + ")").replace("index", i + 1);
        return $("#least-expensive tbody").append(tr);
      });
      $("#most-expensive tbody").html('');
      return expensive.forEach(function(p, i) {
        var tr;
        tr = s.replace("name", p.provider.name + " (" + p.provider.city + ", " + p.provider.state_code + ")").replace("index", i + 1);
        return $("#most-expensive tbody").append(tr);
      });
    };

    GeoChart.prototype.renderProviders = function(providers) {
      var geoPositions, ids, paymentsSorted, size, sorted, that,
        _this = this;
      this.providers = providers;
      ids = _.pluck(providers, 'provider_id');
      this.selected['charges'] = ids;
      this.selected['payments'] = ids;
      that = this;
      d3.select("#provider-count").text(providers.length);
      geoPositions = [];
      providers.forEach(function(o) {
        var location;
        location = [+o.provider.longitude, +o.provider.latitude];
        return geoPositions.push(_this.projection(location));
      });
      this.svg.selectAll("circle").remove();
      this.svg.selectAll("circle").data(providers).enter().append("circle").attr("class", "shown").attr("title", this.tooltipText).on("mouseover", function(d) {
        return d3.select(this).style("fill-opacity", 1.0).style("stroke-width", 1.0).attr("r", 5);
      }).on("mouseout", function(d) {
        return d3.select(this).style("fill-opacity", 0.5).style("stroke-width", 0.2).attr("r", 4);
      }).on("click", this.handleClick).attr("r", 4).attr("cx", function(d, i) {
        return geoPositions[i][0];
      }).attr("cy", function(d, i) {
        return geoPositions[i][1];
      });
      sorted = _.sortBy(providers, function(provider) {
        return provider.avg_covered_charges;
      });
      paymentsSorted = _.sortBy(providers, function(provider) {
        return provider.avg_covered_charges;
      });
      size = providers.length;
      this.updateLabels('charges', "$" + Math.floor(sorted[0].avg_covered_charges), "$" + Math.floor(sorted[size - 1].avg_covered_charges));
      this.updateLabels('payments', "$" + Math.floor(sorted[0].avg_total_payments), "$" + Math.floor(sorted[size - 1].avg_total_payments));
      this.updateList(sorted);
      return this.attachTooltips();
    };

    return GeoChart;

  })();

  BarChart = (function() {

    function BarChart() {
      this.mouseOver = __bind(this.mouseOver, this);

      this.computeChargesDifference = __bind(this.computeChargesDifference, this);

      this.computeDifference = __bind(this.computeDifference, this);
      this.margin = {
        top: 10,
        bottom: 10,
        left: 80,
        right: 60
      };
      this.width = 820 - this.margin.left - this.margin.right;
      this.height = 500 - this.margin.top - this.margin.bottom;
      this.indicator = 'National';
      this.data;
      this.precisionFormat = d3.format(".2f");
      this.x = d3.scale.ordinal().rangeRoundBands([0, this.width], .1);
      this.y = d3.scale.linear().range([this.height, 0]);
      this.yAxis = d3.svg.axis().scale(this.y).orient("left");
      this.svg = d3.select("#difference").append("svg").attr("width", this.width + this.margin.left + this.margin.right).attr("height", this.height + this.margin.top + this.margin.bottom).append("g").attr("transform", "translate(" + this.margin.left + "," + this.margin.top + ")");
    }

    BarChart.prototype.computeDifference = function(d) {
      if (this.indicator === 'National') {
        return d.avg_total_payments - d.weighted_mean_payments;
      } else {
        return d.avg_total_payments - d.state_avg_total_payments;
      }
    };

    BarChart.prototype.computeChargesDifference = function(d) {
      if (this.indicator === 'National') {
        return d.avg_covered_charges - d.weighted_mean_charges;
      } else {
        return d.avg_covered_charges - d.state_avg_covered_charges;
      }
    };

    BarChart.prototype.mouseOver = function(d) {
      var charges, chargesDiff, diff, payments, suffix;
      d3.select("#drg-name").text(d.drg_definition);
      diff = this.precisionFormat(this.computeDifference(d));
      if (diff > 0) {
        diff = "+" + diff;
      }
      suffix = this.indicator === 'National' ? 'Nationally' : 'State wide';
      payments = "$" + this.precisionFormat(d.avg_total_payments) + " (" + diff + ") " + suffix;
      d3.select("#drg-payments").text(payments);
      chargesDiff = this.precisionFormat(this.computeChargesDifference(d));
      if (chargesDiff > 0) {
        chargesDiff = "+" + chargesDiff;
      }
      charges = "$" + this.precisionFormat(d.avg_covered_charges) + " (" + chargesDiff + ") " + suffix;
      d3.select("#drg-charges").text(charges);
      return d3.select("#drg-discharges").text(d.total_discharges);
    };

    BarChart.prototype.mouseOut = function(d) {
      return d3.select(this).style("stroke-width", 0);
    };

    BarChart.prototype.update = function(indicator) {
      var t1,
        _this = this;
      this.indicator = indicator;
      this.y.domain(d3.extent(this.data.charges, this.computeDifference)).nice();
      t1 = this.svg.transition().duration(750);
      t1.select(".x.axis line").attr("y1", this.y(0)).attr("y2", this.y(0));
      t1.select(".y.axis").call(this.yAxis);
      return t1.selectAll(".bar").attr("class", function(d) {
        if (_this.computeDifference(d) < 0) {
          return 'bar negative';
        } else {
          return 'bar positive';
        }
      }).attr("y", function(d) {
        return _this.y(Math.max(0, _this.computeDifference(d)));
      }).attr("height", function(d) {
        return Math.abs(_this.y(1) - _this.y(_this.computeDifference(d)));
      });
    };

    BarChart.prototype.render = function(data) {
      var that,
        _this = this;
      this.data = data;
      d3.select("#provider-name").text(this.data.name + " (" + this.data.city + ", " + this.data.state_code + ")");
      this.x.domain(this.data.charges.map(function(d) {
        return d.id;
      }));
      this.y.domain(d3.extent(this.data.charges, this.computeDifference)).nice();
      that = this;
      this.svg.append("text").attr("transform", "translate(" + this.width / 2 + "," + this.height - 20 + ")").text("Diagnostic Related Group(DRG)");
      this.svg.select(".x.axis").remove();
      this.svg.append("g").attr("class", "x axis").append("line").attr("x2", this.width).attr("y1", this.y(0)).attr("y2", this.y(0)).style("stroke-width", 0.5);
      this.svg.select(".y.axis").remove();
      this.svg.append("g").attr("class", "y axis").call(this.yAxis).append("text").attr("transform", "translate(-60," + this.width / 2 + ")" + "rotate(-90)").text("Difference with Weighted Average Payments Nationally");
      this.svg.selectAll(".bar").remove();
      return this.svg.selectAll(".bar").data(this.data.charges).enter().append("rect").attr("class", "bar").attr("class", function(d) {
        if (_this.computeDifference(d) < 0) {
          return 'bar negative';
        } else {
          return 'bar positive';
        }
      }).attr("x", function(d) {
        return _this.x(d.id);
      }).attr("width", this.x.rangeBand()).attr("y", function(d) {
        return _this.y(Math.max(0, _this.computeDifference(d)));
      }).attr("height", function(d) {
        return Math.abs(_this.y(1) - _this.y(_this.computeDifference(d)));
      }).on("mouseover", function(d) {
        d3.select(this).style("stroke-width", 1.0);
        return that.mouseOver(d);
      }).on("mouseout", this.mouseOut);
    };

    return BarChart;

  })();

  geoChart = null;

  drgs = [];

  container = new HexContainer('#chart');

  barChart = new BarChart();

  first = null;

  second = null;

  $(function() {
    $(".dropdown-menu").on("click", "li a", function(e) {
      var $target, id, meanCharges, meanPayments, name;
      $target = $(e.currentTarget);
      id = $target.data('id');
      meanPayments = $target.data('payments');
      meanCharges = $target.data('charges');
      name = $target.text();
      $("#select-msg").text(name);
      container.meanPayments = meanPayments;
      container.meanCharges = meanCharges;
      return d3.json("/providers/inpatient_charges.json?id=" + id, renderContainer);
    });
    return $("#comparator").on("click", "a", function(e) {
      var $target;
      $target = $(e.currentTarget);
      $("#comparator a").toggleClass("active");
      e.preventDefault();
      console.log($target.html());
      return barChart.update($target.html());
    });
  });

  storeDrgs = function(error, data) {
    drgs = data;
    return data.forEach(function(d) {
      var elem;
      elem = "<li><a data-id=" + d.id + " data-payments=" + d.weighted_mean_payments + " data-charges=" + d.weighted_mean_charges + " href=#>" + d.definition + "</a></li>";
      return $(".dropdown-menu").append(elem);
    });
  };

  renderMap = function(error, data) {
    geoChart = new GeoChart(data, '#map', barChart);
    return geoChart.render();
  };

  renderContainer = function(error, data) {
    var cloned;
    if (!first) {
      first = new HexChart(data, geoChart, container, 'charges', 0);
    } else {
      first.data = data;
    }
    cloned = JSON.parse(JSON.stringify(data));
    if (!second) {
      second = new HexChart(cloned, geoChart, container, 'payments', 80);
    } else {
      second.data = cloned;
    }
    first.render();
    first.geo.renderProviders(data);
    return second.render();
  };

  d3.json("/providers/drgs.json", storeDrgs);

  d3.json("us-named.json", renderMap);

}).call(this);
