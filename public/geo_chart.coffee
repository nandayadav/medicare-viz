class HexContainer
  constructor: (@div) ->

    @margin = 
      top: 5
      bottom: 0
      left: 0
      right: 20
  
    
    @width = 990 - @margin.left - @margin.right
    @height = 140 - @margin.top - @margin.bottom
    
    @meanPayments = null
    @meanCharges = null

    
    @svg = d3.select(@div).append("svg")
                      .attr("width", @width + @margin.left + @margin.right)
                      .attr("height", @height + @margin.top + @margin.bottom)
                  .append("g")
                      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
    
class HexChart
  constructor: (@data, @geo, @container, @indicator, @yPosition) ->
    
    @width = @container.width - 300
    @height = @container.height
    @color = d3.scale.linear()
                      .range(["white", "red"])
                      .interpolate(d3.interpolateLab)
      
    @xScale = d3.scale.linear()
                               .range([0, @width])
                               
    @hexHeight = 25
    @hexRadius = 2
    

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
                        .size([@width, @hexHeight])
                        .radius(@hexRadius)
                        
    @brush = d3.svg.brush()
                      .x(@xScale)
                      .on("brush", @brushMove)
                      
    @precisionFormat = d3.format(".2f")
                  
    
    #accessors from container                  
    @svg = @container.svg
                      .append("g")
                        .attr("transform", "translate(" + 0 + "," + @yPosition + ")")
                      
                      
    @svg.append("clipPath")
              .attr("id", "clip")
            .append("rect")
              .attr("class", "mesh")
              .attr("width", @width)
              .attr("height", @hexHeight)
              
    @svg.append("text")
              .attr('x', @width + 10)
              .attr('y', 25)
              .text(@capitalize(@indicator))
            
              
  renderComparison: () ->   
    percentage = @precisionFormat((@container.meanPayments / @container.meanCharges) * 100) + "%"
    d3.select(".progress-bar").style("width", percentage)
    d3.select("#difference-ratio").text(percentage)
                      
  brushMove: () =>
    e = d3.event.target.extent()
    selected = []
    #Click on the background
    if (e[0] == e[1]) 
      @geo.renderSelected(@data, @indicator, @xScale.invert(0), @xScale.invert(@width))
    else
      @data.forEach (d) ->
        selected.push(d) if (e[0] <= d.x && d.x <= e[1])
      @geo.renderSelected(selected, @indicator, e[0], e[1])

  
  capitalize: (str) ->
    str.charAt(0).toUpperCase() + str.substring(1).toLowerCase()
  
  xIndicator: (d) =>
   #d.avg_total_payments;
    if @indicator == 'payments' then d.avg_total_payments else d.avg_covered_charges
  
    
  render: () ->
    if @indicator == 'charges'
      @renderComparison()
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
    
    #Store all providers
    @providers = [] 
      
    @width = 900 - @margin.left - @margin.right
    @height = 640 - @margin.top - @margin.bottom
                      
    @projection = d3.geo.albersUsa()
                                     .scale(1100)
                                     .translate([480, 270])
                                     
    @path = d3.geo.path()
                             .projection(@projection)
                             
    @precisionFormat = d3.format(".2f")

                             
    @states = []
    @circles = []
    
    #Store currently selected provider_ids for both sets of indicator
    @selected = {charges: [], payments: []}
    
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
    
    @renderProviders
    
  
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
    
    
  mouseDown: (d) =>
    selected = d3.select(d3.event.target)
    @findSimilar(d)
    selected.attr("r", 10)
    
  mouseUp: (d) =>
    selected = d3.select(d3.event.target)
    selected.attr("r", 4)
    @svg.selectAll("circle.shown").each (d) ->
      d3.select(this).attr("r", 4)
      
  updateLabels: (indicator, left, right) ->
    selector = "#" + indicator
    d3.select(selector + "-left").text(left)
    d3.select(selector + "-right").text(right)
    
    
  #Applies intersection to selected provider_ids of both indicators and renders that only, while hiding the rest
  renderSelected: (providers, bucket, left, right) =>
    ids = _.pluck(providers, 'provider_id')
    otherAttr = if bucket == 'charges' then 'payments' else 'charges'
    other = @selected[otherAttr]
    
    #Only update & render if selection has actually changed
    #TODO: fix this logic, its buggy
    if (ids.length != @selected[bucket].length)
      @selected[bucket] = ids
      intersection = _.intersection(ids, other)
      d3.select("#provider-count").text(intersection.length)
      leftText = "$" + Math.floor(left)
      rightText = "$" + Math.floor(right)
      @updateLabels(bucket, leftText, rightText)
        
      @svg.selectAll("circle").each (d) ->
        if _.contains(intersection, d.provider_id)
          d3.select(this).attr("r", 4).classed("shown", true)
        else
          d3.select(this).attr("r", 0).classed("shown", false)
            
      #Filter & Sort the selection
      sorted = _.filter(@providers, (p) -> _.contains(intersection, p.provider_id))
      sorted = _.sortBy(sorted, (provider) -> provider.avg_covered_charges)
      
      @updateList(sorted)  
  
  #Update top 5 and bottom 5 table  
  #Feed in sorted providers by avg_covered_charges  
  updateList: (sorted) ->
    size = sorted.length
    cheapest = sorted.slice(0,5)
    expensive = sorted.slice(size - 5, size)
    s = "<tr>
              <td>index</td>
              <td>name</td>
            </tr>"
    $("#least-expensive tbody").html('')
    
    cheapest.forEach (p, i) ->
      tr = s.replace("name", p.provider.name + " (" + p.provider.city + ", " + p.provider.state_code + ")").replace("index", i + 1)
      $("#least-expensive tbody").append(tr)
      
    $("#most-expensive tbody").html('')
    expensive.forEach (p, i) ->
      tr = s.replace("name", p.provider.name + " (" + p.provider.city + ", " + p.provider.state_code + ")").replace("index", i + 1)
      $("#most-expensive tbody").append(tr)
    
  #Initial Render of all providers
  renderProviders: (providers) ->
    @providers = providers
    ids = _.pluck(providers, 'provider_id')
    @selected['charges'] = ids
    @selected['payments'] = ids
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
      )
      .on("mouseout", (d) -> 
        d3.select(this).style("fill-opacity", 0.5).style("stroke-width", 0.2)
      )
      .attr("r", 4)
      .attr("cx", (d, i) -> geoPositions[i][0])
      .attr("cy", (d, i) -> geoPositions[i][1])
    sorted = _.sortBy(providers, (provider) -> provider.avg_covered_charges)
    paymentsSorted = _.sortBy(providers, (provider) -> provider.avg_covered_charges)
    size = providers.length
    @updateLabels('charges', "$" + Math.floor(sorted[0].avg_covered_charges), "$" + Math.floor(sorted[size-1].avg_covered_charges))
    @updateLabels('payments', "$" + Math.floor(sorted[0].avg_total_payments), "$" + Math.floor(sorted[size-1].avg_total_payments))
    @updateList(sorted)  
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
    id = $target.data('id')
    meanPayments = $target.data('payments')
    meanCharges = $target.data('charges')
    name = $target.text()
    $("#select-msg").text(name)
    container.meanPayments = meanPayments
    container.meanCharges = meanCharges
    d3.json "/providers/inpatient_charges.json?id=" + id, renderContainer
  )


storeDrgs = (error, data) ->
  drgs = data
  data.forEach (d) ->
    elem = "<li><a data-id=" + d.id + " data-payments=" + d.weighted_mean_payments + " data-charges=" + d.weighted_mean_charges + " href=#>" + d.definition + "</a></li>"
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



