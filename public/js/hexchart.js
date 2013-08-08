   var margin = {top: 5, right: 0, bottom: 0, left: 50};
   var width = 1200 - margin.left - margin.right,
        height = 700 - margin.top - margin.bottom;
        
  var color = d3.scale.quantize()
                              .range(colorbrewer.Reds[9]);
                              
  var bubbleColor = d3.scale.quantize()
                                .range(colorbrewer.Blues[9]);
  
  var radiusScale = d3.scale.linear()
                                .range([20, 60]);
                                
                       
  var projection = d3.geo.albersUsa()
                                     .scale(1320)
                                     .translate([640, 330]);
    
  var path = d3.geo.path()
                             .projection(projection);
                             
  var mapsScalingFactor = 0.7;   
  var attribute = "std_deviation";
  
  var root, circles, nodes, pack_node, states, statesData;
  var geoPositions = [];
            
  var svg = d3.select("#chart").append("svg")
                      .attr("width", width + margin.left + margin.right)
                      .attr("height", height + margin.top + margin.bottom)
                  .append("g")
                      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
                    
  d3.json("us-named.json", function(error, topology) {
    var geometries = topojson.object(topology, topology.objects.states).geometries;
    var filtered = geometries.filter(function(d) { return d.properties.code == "TX"; });
    states = svg.selectAll("path")
        .data(geometries)
      .enter().append("path")
        .attr("d", path);
    //loadProviders();
    loadStatesData();
    //loadProviders();
  });
  
  function loadStatesData() {
    d3.json("/providers/states", function(error, data) {
      //color.domain(d3.extent(data, function(d) { return d.std_deviation_payments; })); 
      statesData = data;
      //states.style("fill", findStateColor);
    });
  }
  
  function findStateColor(d) {
    var code = d.properties.code;
    var selected = statesData.filter(function(s) { return s.abbreviation == code; })[0];
    if (selected) 
      return color(correctAttribute(selected));
    else //For puerto rico 
      return "green";
  }
  
  function loadProviders() {
    d3.json("/providers", function(error, data) {
      bubbleColor.domain(d3.extent(data, function(d) { return d.provider.total_payments; })); 
      data.forEach(function(o) {
        var location = [+o.provider.longitude, +o.provider.latitude];
        geoPositions.push(projection(location));
      });
      
      circles = svg.selectAll(".circle")
        .data(data)
      .enter().append("circle")
        .attr("class", "circle")
        .attr("r", 3)
        .style("fill", function(d) { return bubbleColor(d.provider.total_payments); })
        .attr("cx", function(d, i) { return geoPositions[i][0]; })
        .attr("cy", function(d, i) { return geoPositions[i][1]; });
      
    });
  }
  

  function moveElements() {                      
    circles.attr("cx", function(d) { return d.x; })
             .attr("cy", function(d) { return d.y; });
  }
  
  function correctAttribute(d) {
    if (attribute == "std_deviation_payments")
      return d.std_deviation_payments;
    else if (attribute == "total_payments")
      return d.total_payments;
    else if (attribute == "survey_not_recommended")
      return d.survey_not_recommended;
    else if (attribute == "survey_definitely_recommended")
      return d.survey_definitely_recommended;
    else if (attribute == "count")
      return d.count;
    else if (attribute == "std_deviation_charges")
      return d.std_deviation_charges;
    else if (attribute == "std_deviation_discharges")
      return d.std_deviation_discharges;
  }
  
  //Reload map with selected attribute/stat
  function reloadChart() {
    attribute = this.value;
    color.domain(d3.extent(statesData, correctAttribute)); 
    states.style("fill", findStateColor);
  }
  
  $(function() {
    d3.select("#mapSelector")
      .on("change", reloadChart);
  });
    
