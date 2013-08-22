class HexContainer
  constructor: (@div) ->

    @margin = 
      top: 5
      bottom: 0
      left: 0
      right: 10
      
    @selected = []
    
    @width = 800 - @margin.left - @margin.right
    @height = 140 - @margin.top - @margin.bottom
    
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
                        .tickPadding("4")
                        .orient("bottom")
                        
    @hexbin = d3.hexbin()
                        .size([@container.width, @hexHeight])
                        .radius(@hexRadius)
                        
    @brush = d3.svg.brush()
                      .x(@xScale)
                      .on("brush", @brushMove)
                      .on("brushend", @brushEnd)
                  
    
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
    
    @geo.renderSelected(selected, @indicator, e[0], e[1])
    
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
    @xScale.domain(d3.extent(@data, @xIndicator))
    @xAxis.scale(@xScale)
    @data.forEach (d, i) =>
      d.x = @xIndicator(d)
      d.y = 1
      _.range(1, 43, 3).forEach (y) =>
        points.push [@xScale(d.x), @yScale(y)]

    @color.domain([0, d3.max(@hexbin(points), (d) -> d.length * 0.5)])
    
    @svg.select("g.x.axis").remove()
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
    
    #@updateList(@data)
    #@geo.renderProviders(@data)
      
class GeoChart
  constructor: (@topology, @div) ->
    @margin = 
      top: 0
      bottom: 0
      left: 0
      right: 0
      
    @width = 900 - @margin.left - @margin.right
    @height = 640 - @margin.top - @margin.bottom
                      
    @projection = d3.geo.albersUsa()
                                     .scale(1100)
                                     .translate([480, 270])
                                     
    @path = d3.geo.path()
                             .projection(@projection)
                             
    @precisionFormat = d3.format(".2f")

    @centered
                             
    @states = []
    @circles = []
    @selected = {charges: [], payments: []}
    
    @color = d3.scale.quantize()
                              .range(colorbrewer.Reds[9])
                              #.domain([0,100])
    
    @svg = d3.select(@div).append("svg")
                      .attr("width", @width + @margin.left + @margin.right)
                      .attr("height", @height + @margin.top + @margin.bottom)
                  .append("g")
                      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
  
  
  handleStateClick: (d) =>
    x = null
    y = null
    z = null

    if (d && @centered != d)
      centroid = @path.centroid(d)
      x = centroid[0]
      y = centroid[1]
      k = 4
      @centered = d
    else
      x = @width / 2
      y = @height / 2
      k = 1;
      @centered = null
    
    # @states.classed("active", @centered && (d) ->  d == @centered)
    # @states.forEach (d) =>
    #   if (@centered && (d) -> d == @centered)
    #     d3.select(this).style("display: block;")
    #   else
    #     d3.select(this).style("display: none;")
    @states.classed("inactive", @centered && (d) -> d != @centered )
        

    @states.transition()
        .duration(750)
        .attr("transform", "translate(" + @width / 2 + "," + @height / 2 + ")scale(" + k + ")translate(" + -x + "," + -y + ")")
        .style("stroke-width", 1.5 / k + "px")
    
  #Render the map, excluding PR and virgin islands
  render: () ->
    geometries = topojson.object(@topology, @topology.objects.states)
                          .geometries.filter (d) ->
                            d.properties.code != 'VI' && d.properties.code != 'PR'
    @states = @svg.selectAll("path")
        .data(geometries)
      .enter().append("path")
        .attr("d", @path)
        .on("click", @handleStateClick)
    
    @renderProviders
    
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
    d.provider.name + "<br/>" + d.provider.city + ", " + d.provider.state_code + "<br/>Avg payments: $" + @precisionFormat(d.avg_total_payments) + "<br/>Avg Charges: $" + @precisionFormat(d.avg_covered_charges) + "<br/>Total Discharges: " + d.total_discharges;
  
  #Find n similar providers 
  findSimilar: (selected) =>
    threshold = 10.0
    @svg.selectAll("circle.shown").each (d) ->
      circle = d3.select(this)
      if Math.abs(d.avg_total_payments - selected.avg_total_payments) < threshold
        circle.attr("r", 10)
      else
        circle.attr("r", 0)
      
      
  mouseOver: (d) =>
    $(".panel-body p").text(d.provider.name + ", " + d.provider.city + ", " + d.provider.state_code)
    $("#charges-text").val("$ " + Math.floor(d.avg_covered_charges))
    $("#payments-text").val("$ " + Math.floor(d.avg_total_payments))
    $("#discharges-text").val(d.total_discharges)
    
    
    
  mouseOut: (d) =>
    $(".panel-body p").text("")
    $("#charges-text").val("")
    $("#payments-text").val("")
    $("#discharges-text").val("")
    
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
  renderSelected: (providers, bucket, left, right) =>
    ids = _.pluck(providers, 'provider_id')
    @selected[bucket] = ids
    otherAttr = if bucket == 'charges' then 'payments' else 'charges'
    other = @selected[otherAttr]
    intersection = []
    if (_.isEmpty(other) && !_.isEmpty(ids))
      intersection = ids
    else if (_.isEmpty(ids) && !_.isEmpty(other))
      intersection = other
    else
      intersection = _.intersection(ids, other)
    d3.select("#provider-count").text(intersection.length)
    leftText = "$ " + Math.floor(left)
    rightText = "$ " + Math.floor(right)
    if bucket == 'charges'
      d3.select("#charges-left").text(leftText)
      d3.select("#charges-right").text(rightText)
    else
      d3.select("#payments-left").text(leftText)
      d3.select("#payments-right").text(rightText)
      
    @svg.selectAll("circle").each (d) ->
      if _.contains(intersection, d.provider_id)
        d3.select(this).attr("r", 4).classed("shown", true)
      else
        d3.select(this).attr("r", 0).classed("shown", false)
    #@updateList(intersection)  
  
  #Update top 5 and bottom 5 table    
  updateList: (providers) ->
    sorted = _.sortBy(providers, (provider) -> provider.avg_covered_charges)
    size = providers.length
    cheapest = sorted.slice(0,5)
    expensive = sorted.slice(size - 5, size)
    s = "<tr>
              <td>index</td>
              <td>name</td>
            </tr>"
    cheapest.forEach (p, i) ->
      tr = s.replace("name", p.provider.name).replace("index", i + 1)
      $("#least-expensive tbody").append(tr)
      
    expensive.forEach (p, i) ->
      tr = s.replace("name", p.provider.name).replace("index", i + 1)
      $("#most-expensive tbody").append(tr)
    
  #Initial Render of all providers
  renderProviders: (providers) ->
    that = @
    d3.select("#provider-count").text(providers.length)
    geoPositions = []
    providers.forEach (o) =>
      location = [+o.provider.longitude, +o.provider.latitude]
      geoPositions.push(@projection(location))
    
    #@circles.remove() if @circles
    @svg.selectAll("circle").remove()
    @svg.selectAll("circle")
      .data(providers)
    .enter().append("circle")
      .attr("class", "shown")
      .attr("title", @tooltipText)
      .on("mouseover", (d) -> 
        d3.select(this).style("fill-opacity", 1.0).style("stroke-width", 1.0)
        #that.mouseOver(d)
      )
      .on("mouseout", (d) -> 
        d3.select(this).style("fill-opacity", 0.5).style("stroke-width", 0.2)
        #that.mouseOut(d)
      )
      .attr("r", 4)
      .attr("cx", (d, i) -> geoPositions[i][0])
      .attr("cy", (d, i) -> geoPositions[i][1])
    
    @updateList(providers)  
    @attachTooltips()
    

#Some globals
geoChart = null
drgs = []
container = new HexContainer('#chart')
first = null
second = null

$ ->
  $(".dropdown-menu").on("click", "li a", (e) ->
    $target = $(e.currentTarget)
    href = $target.attr('href')
    name = $target.text()
    $("#select-msg").text(name)
    
    id = href.replace("#", "")
    d3.json "/providers/inpatient_charges_new.json?id=" + id, renderContainer
  )


storeDrgs = (error, data) ->
  drgs = data
  data.forEach (d) ->
    elem = "<li><a href='#" + d.id + "'>" + d.definition + "</a></li>"
    $(".dropdown-menu").append(elem)
  

renderMap = (error, data) ->
  geoChart = new GeoChart(data, '#map')
  geoChart.render()   
  
renderContainer = (error, data) ->
  if !first
    first = new HexChart(data, geoChart, container, 'charges', 0)
  else
    first.data = data

  cloned = JSON.parse(JSON.stringify(data))
  if !second
    second = new HexChart(cloned, geoChart, container, 'payments', 80)
  else
    second.data = cloned
    
  first.render()
  first.geo.renderProviders(data)
  second.render()
  
# $ ->
d3.json "/providers/drgs.json", storeDrgs
  
    
d3.json "us-named.json", renderMap



