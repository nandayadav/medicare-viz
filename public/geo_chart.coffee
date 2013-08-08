class HexContainer
  constructor: (@div) ->

    @margin = 
      top: 20
      bottom: 10
      left: 10
      right: 10
      
    @selected = []
    
    @width = 800 - @margin.left - @margin.right
    @height = 100 - @margin.top - @margin.bottom
    
    @svg = d3.select(@div).append("svg")
                      .attr("width", @width + @margin.left + @margin.right)
                      .attr("height", @height + @margin.top + @margin.bottom)
                  .append("g")
                      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
    
class HexChart
  constructor: (@data, @geo, @container, @indicator, @yPosition) ->
    @color = d3.scale.linear()
                      .range(["white", "red"])
                      .interpolate(d3.interpolateLab)
      
    @xScale = d3.scale.linear()
                               .range([0, @container.width])
                               
    @hexHeight = 25
    @hexRadius = 2
    @height = @container.height
    @width = @container.width

    @yScale = d3.scale.linear()
                               .range([@hexHeight, 1])
                               .domain([@hexHeight, 1])
                               
                               
    @xAxis = d3.svg.axis()
                        .scale(@xScale)
                        .ticks(7)
                        .tickSize(10)
                        .tickPadding("10")
                        .orient("bottom")
                        
    @hexbin = d3.hexbin()
                        .size([@container.width, @hexHeight])
                        .radius(@hexRadius)
                        
    @brush = d3.svg.brush()
                      .x(@xScale)
                      .on("brush", this.brushMove)
                      .on("brushend", this.brushEnd)
    
    #accessors from container                  
    @svg = @container.svg
                      .append("g")
                        .attr("transform", "translate(" + 0 + "," + @yPosition + ")")
                      
    @text = @svg.append("text")
            .attr("x", @width/4)
            .attr("y", -4)
            .text("")
                      
    @svg.append("clipPath")
              .attr("id", "clip")
            .append("rect")
              .attr("class", "mesh")
              .attr("width", @width)
              .attr("height", @hexHeight)
                      
  brushMove: () =>
    e = d3.event.target.extent()
    selected = []
    @data.forEach (d) ->
      selected.push(d) if (e[0] <= d.x && d.x <= e[1])

    @geo.renderSelected selected
    
  brushEnd: () =>
    # e = d3.event.target.extent()
    # selected = []
    # @data.forEach (d) =>
    #   selected.push(d) if (e[0] <= d.x && d.x <= e[1])
    
    # @geo.renderSelected selected
    

  xIndicator: (d) =>
   #d.avg_total_payments;
    if @indicator == 'payments' then d.avg_total_payments else d.avg_covered_charges
    
                      
  render: () ->
    points = []
    #@xScale.domain([0, d3.max(@data, this.xIndicator)])
    @xScale.domain(d3.extent(@data, this.xIndicator))
    @xAxis.scale(@xScale)
    @data.forEach (d, i) =>
      d.x = this.xIndicator(d)
      d.y = 1
      _.range(1, 43, 3).forEach (y) =>
        points.push [@xScale(d.x), @yScale(y)]

    @color.domain([0, d3.max(@hexbin(points), (d) -> d.length * 0.5)])
    
    #@svg.select("g.x.axis").remove()
    @svg.append("g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + @hexHeight + ")")
                  .call(@xAxis)
                  
    if (@hexagons)
      @hexagons.remove()
    
    @hexagons = @svg.append("g")
        .attr("clip-path", "url(#clip)")
      .selectAll(".hexagon")
        .data(@hexbin(points))
      .enter().append("path")
        .attr("class", "hexagon")
        .attr("d", @hexbin.hexagon())
        .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")" )
        .style("fill", (d) => @color(d.length))
        
    @svg.append("g")
      .attr("class", "brush")
      .call(@brush)
      .selectAll("rect")
      .attr("y", 0)
      .attr("height", @hexHeight)
      
    @text.text(@data[0].drg)
    
    @geo.renderProviders(@data)
      
class GeoChart
  constructor: (@topology, @div) ->
    @margin = 
      top: 5
      bottom: 0
      left: 10
      right: 10
      
    @width = 1200 - @margin.left - @margin.right
    @height = 700 - @margin.top - @margin.bottom
                      
    @projection = d3.geo.albersUsa()
                                     .scale(1200)
                                     .translate([550, 330])
                                     
    @path = d3.geo.path()
                             .projection(@projection)
                             
    @precisionFormat = d3.format(".2f")
                             
    @states = []
    @circles = []
    
    @color = d3.scale.quantize()
                              .range(colorbrewer.Reds[9])
                              #.domain([0,100])
    
    @svg = d3.select(@div).append("svg")
                      .attr("width", @width + @margin.left + @margin.right)
                      .attr("height", @height + @margin.top + @margin.bottom)
                  .append("g")
                      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
   
  #Render the map, excluding PR and virgin islands
  render: () ->
    geometries = topojson.object(@topology, @topology.objects.states)
                          .geometries.filter (d) ->
                            d.properties.code != 'VI' && d.properties.code != 'PR'
    @states = @svg.selectAll("path")
        .data(geometries)
      .enter().append("path")
        .attr("d", @path)
    
  #Render chloropeth
  renderChrolopeth: (providers) ->
    statesFrequency = {}
    providers.forEach (p) =>
      if (statesFrequency[p])
        statesFrequency[p] += 1
      else
        statesFrequency[p] = 1
    #recompute the color domain
    @color.domain([0, d3.max(_.values(statesFrequency))])
    #bubbleColor.domain(d3.extent(data, function(d) { return d.provider.total_payments; })); 
      
    @states.style("fill", (d) => @color(statesFrequency[d.properties.code] || 0))
    
  
  attachTooltips: () ->
    $("circle").tooltip({ position: { my: "left+15 center", at: "top center" }, show: true })
    
  tooltipText: (d) =>
    d.provider_name + "<br/>" + d.provider_city + ", " + d.state_code + "<br/>Avg payments: " + @precisionFormat(d.avg_total_payments) + "<br/>Charges: " + @precisionFormat(d.avg_covered_charges)
  
  #Find n similar providers 
  findSimilar: (selected) =>
    threshold = 10.0
    @svg.selectAll("circle.shown").each (d) ->
      circle = d3.select(this)
      if Math.abs(d.avg_total_payments - selected.avg_total_payments) < threshold
        circle.attr("r", 10)
      else
        circle.attr("r", 0)
      
      
  mouseDown: (d) =>
    selected = d3.select(d3.event.target)
    @findSimilar(d)
    selected.attr("r", 10)
    
  mouseUp: (d) =>
    selected = d3.select(d3.event.target)
    selected.attr("r", 4)
    @svg.selectAll("circle.shown").each (d) ->
      d3.select(this).attr("r", 4)
    
  #Render selected providers, (show/hide already rendered circles) 
  renderSelected: (providers) ->
    ids = _.pluck(providers, 'provider_id')
    @svg.selectAll("circle").each (d) ->
      if _.contains(ids, d.provider_id)
        d3.select(this).attr("r", 4).classed("shown", true)
      else
        d3.select(this).attr("r", 0).classed("shown", false)
      
      
    
  #Initial Render of all providers
  renderProviders: (providers) ->
    geoPositions = []
    providers.forEach (o) =>
      location = [+o.longitude, +o.latitude]
      geoPositions.push(@projection(location))
    
    #@circles.remove() if @circles
    @svg.selectAll("circle").remove()
    @svg.selectAll("circle")
      .data(providers)
    .enter().append("circle")
      .attr("class", "shown")
      .attr("title", @tooltipText)
      .on("mouseover", (d) -> d3.select(this).style("fill-opacity", 1.0).style("stroke-width", 1.0))
      .on("mouseout", (d) -> d3.select(this).style("fill-opacity", 0.5).style("stroke-width", 0.2))
      .on("mousedown", @mouseDown)
      .on("mouseup", @mouseUp)
      .attr("r", 4)
      .attr("cx", (d, i) -> geoPositions[i][0])
      .attr("cy", (d, i) -> geoPositions[i][1])
      
    @attachTooltips()

#Some globals
geoChart = null

renderMap = (error, data) ->
  geoChart = new GeoChart(data, '#map')
  geoChart.render()   
  
renderContainer = (error, data) ->
  container = new HexContainer('#chart')
  first = new HexChart(data, geoChart, container, 'payments', 0)
  first.render()
  # second = new HexChart(data, geoChart, container, 'charges', 120)
  # second.render()
  
d3.json "us-named.json", renderMap

d3.json "/providers/inpatient_charges.json", renderContainer


