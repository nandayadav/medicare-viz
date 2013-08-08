var margin = {top: 30, right: 20, bottom: 30, left: 70},
    width = 960 - margin.left - margin.right,
    height = 200 - margin.top - margin.bottom;
                            

var hexHeight = 40;                            
var color = d3.scale.linear()
    .domain([0, 50])
    .range(["white", "red"])
    .interpolate(d3.interpolateLab);
    
var xScale = d3.scale.linear()
                               .range([0, width]);

var yScale = d3.scale.linear()
                               .range([hexHeight, 1]);
                               
                               
var xAxis = d3.svg.axis()
                        .scale(xScale)
                        .ticks(7)
                        .tickSize(10)
                        .tickPadding("10")
                        .orient("bottom");
                               
                               
var hexbin = d3.hexbin()
                        .size([width, hexHeight])
                        .radius(8);
    
var songs = [];
var artists = [];
var points = [];
var indicator = 'Songs Count';

var hexagons;
var selected = []; //Hexbins selected by the brush, store artist_id of those within selected bins
var brush = d3.svg.brush()
                      .x(xScale)
                      .y(yScale)
                      .on("brush", brushMove)
                      .on("brushend", brushEnd);

var svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
                           
svg.append("clipPath")
    .attr("id", "clip")
  .append("rect")
    .attr("class", "mesh")
    .attr("width", width)
    .attr("height", hexHeight);

var topLabel = svg.append("text")
      .attr("id", "topLabel")
      .attr("x", width/2 - 60)
      .attr("y", -10)
      .text("");
      
var yPlotLabel = svg.append("text")
      .attr("id", "yPlotLabel")
      .attr("transform", "translate(-30," + (height/2 + 100) + ")rotate(270, 0, 0)" )
      .text("");

var xPlotLabel = svg.append("text")
      .attr("id", "xPlotLabel")
      .attr("x", width/2 - 60)
      .attr("y", height - 20)
      .text("");
      

                      
//************************scatter plot vars****************************************************************//
var xPlot = d3.scale.linear()
                     .range([0, width]);

var yPlot = d3.scale.linear()
                     .range([height - 50, height/3]);

var xAxisPlot = d3.svg.axis()
                           .scale(xPlot)
                           .orient("bottom");

var yAxisPlot = d3.svg.axis()
                           .scale(yPlot)
                           .ticks(5)
                           .orient("left");
                           
 //*******************************************************************************************************//                          

  //Api call
  d3.json("/providers/inpatient_charges.json", function(error, data) {
    artists = data;
    updateChart();
  });


  function brushMove() {
    var e = d3.event.target.extent();
    selected = []; //reset 
    //TODO: use quadtree for more efficient checking of selected artists
    artists.forEach(function(d) {
      if ((e[0][0] <= d.x && d.x <= e[1][0]) && (e[0][1] <= d.y && d.y <= e[1][1])) 
        selected.push(d.provider_id);
    });
    console.log("Selected size: " + selected.length);
    // var range = "[" + d3.round(e[0][0]) + " .. " + d3.round(e[1][0]) + "]";
    // d3.select("#rangeSelection").text(range);
    // var total = selected.length;
    // d3.select("#info p").text(total);
    updatePlot();
  }
  
  function brushEnd() {
    //updatePlot();
  }

  
  function xIndicator(d) {
    return d.avg_total_payments;    
  }
  
  function indicatorsForPlot(d) {
    return { x: d.avg_total_payments, y: d.avg_covered_charges };  
  }
  
  //Refresh scatter plot for selected artists
  function updatePlot() {
    var filtered = _.filter(artists, function(d) { return _.include(selected, d.provider_id); })
    console.log("Filtered: " + filtered.length);
    //Redefine domains
    //xPlot.domain(d3.extent(filtered, function(d) { return indicatorsForPlot(d).x; }));
    //yPlot.domain(d3.extent(filtered, function(d) { return indicatorsForPlot(d).y; }));
    
    // yPlot.domain([1, d3.max(filtered, function(d) { return d.artist.users_count; })] );
    svg.select(".yPlot.axis").remove();
    svg.append("g")
        .attr("class", "yPlot axis")
        .call(yAxisPlot);
        
    svg.select(".xPlot.axis").remove();
    svg.append("g")
                  .attr("class", "xPlot axis")
                  .attr("transform", "translate(0," + (height - 50) + ")")
                  .call(xAxisPlot);
        
    svg.selectAll(".circle").remove();
    svg.selectAll(".circle")
      .data(filtered)
    .enter().append("circle")
      .attr("class", "circle")
      .attr("r", 4)
      .attr("cx", function(d) { return xPlot(indicatorsForPlot(d).x); })
      .attr("cy", function(d) { return yPlot(indicatorsForPlot(d).y); });
    //attachToolTips();
  }
  
  
  function attachToolTips() {
    $(".circle").tooltip({ position: { my: "left+15 center", at: "top center" }, show: true });
  }
  
  function updateLabels() {
    if (indicator == 'Songs Count') {
      yPlotLabel.text("Users Count");
      xPlotLabel.text("Plays Count");
    } else if (indicator == 'Plays Count') {
      yPlotLabel.text("Songs Count");
      xPlotLabel.text("Users Count");
    } else {
      yPlotLabel.text("Songs Count");
      xPlotLabel.text("Plays Count");
    }
  }
  
  function updateChart() {
    points = [];
    xScale.domain([0, d3.max(artists, xIndicator)]);
    yScale.domain([0, 50]);
    //yPlot.domain(d3.extent(filtered, function(d) { return indicatorsForPlot(d).y; }));
    yPlot.domain([0, d3.max(artists, function(d) { return indicatorsForPlot(d).y; })]);
    xPlot.domain([0, d3.max(artists, function(d) { return indicatorsForPlot(d).x; })] );
    //yScale.domain([0, d3.max(artists, function(d) { return d.avg_covered_charges; })])
    xAxis.scale(xScale);
    artists.forEach(function(d, i) { 
      d.x = xIndicator(d);
      // d.y = 5;
      // points.push([xScale(d.x), yScale(d.y)]);
      for (var i=1; i<10; i++) {
        d.y = 6*i;
        points.push([xScale(d.x), yScale(d.y)]);
      }
      d.y = 5;
      //d.y = 5;
      //d.y = d.avg_covered_charges;
      
    });
    
    //TODO: use transitions here...
    svg.select("g.x.axis").remove();
    svg.append("g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + hexHeight + ")")
                  .call(xAxis);
                  
    if (hexagons)
      hexagons.remove();
    
    hexagons = svg.append("g")
        .attr("clip-path", "url(#clip)")
      .selectAll(".hexagon")
        .data(hexbin(points))
      .enter().append("path")
        .attr("class", "hexagon")
        .attr("d", hexbin.hexagon())
        .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
        .style("fill", function(d) { return color(d.length); });

        
    svg.append("g")
      .attr("class", "brush")
      .call(brush);      
  }
  
  $(function() {
    $(".circle").tooltip();
    $("#indicator").on("change", function(e) {
      var $selected = $(this).val();
      indicator = $selected;
      updateLabels();
      updateChart();
    })
  });
