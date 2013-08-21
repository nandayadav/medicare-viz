var margin = {top: 0, right: 0, bottom: 10, left: 0},
    width = 560 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var formatPercent = d3.format(".0%");

var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

var y = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var svg = d3.select("#difference").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.json("/providers/2729", function(error, data) {
  x.domain(data.provider.inpatient_charges.map(function(d) { return d.id; }));
  y.domain([0, d3.max(data.provider.inpatient_charges, function(d) { return d.avg_covered_charges; })]);

  svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

  svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Frequency");

  svg.selectAll(".bar")
      .data(data.provider.inpatient_charges)
    .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x(d.id); })
      .attr("width", x.rangeBand())
      .attr("y", function(d) { return y(d.avg_covered_charges); })
      .attr("height", function(d) { return height - y(d.avg_covered_charges); });

});

function type(d) {
  d.frequency = +d.frequency;
  return d;
}
