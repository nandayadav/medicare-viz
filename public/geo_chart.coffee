class HexContainer
  constructor: (@div) ->

    @margin = 
      top: 5
      bottom: 0
      left: 30
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
    #d3.select(".brush").call(@brush.clear())
    #@xScale.domain([0, d3.max(@data, this.xIndicator)])
    @xScale.domain(d3.extent(@data, @xIndicator)).nice()
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
        
    #@svg.select(".brush").remove()
        
    @svg.append("g")
          .attr("class", "brush")
          .call(@brush)
          .selectAll("rect")
          .attr("y", 0)
          .attr("height", @hexHeight)
    
      
class GeoChart
  constructor: (@topology, @div, @barChart) ->
    @margin = 
      top: 0
      bottom: 0
      left: 0
      right: 0
    
    #Store all providers
    @providers = [] 
      
    @width = 900 - @margin.left - @margin.right
    @height = 540 - @margin.top - @margin.bottom
                      
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
    
  handleClick: (d) =>
    url = "/providers/" + d.provider_id
    that = @
    dest
    if ($('#difference').offset().top > $(document).height() - $(window).height())
      dest = $(document).height() - $(window).height()
    else
      dest = $('#difference').offset().top
      
    $('html,body').animate({scrollTop: dest}, 500, 'swing')
    d3.json url, (error, data) ->
      # that.barChart.render(data)
      that.barChart.renderWithSelection(data, d.diagnostic_related_group_id)
    
    
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
        d3.select(this).style("fill-opacity", 1.0).style("stroke-width", 1.0).attr("r", 5)
      )
      .on("mouseout", (d) -> 
        d3.select(this).style("fill-opacity", 0.5).style("stroke-width", 0.2).attr("r", 4)
      )
      .on("click", @handleClick)
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
    
class BarChart
  constructor: () ->
    @margin = 
      top: 10
      bottom: 10
      left: 80
      right: 60
      
    @width = 820 - @margin.left - @margin.right
    @height = 500 - @margin.top - @margin.bottom
    
    @indicator = 'National'
    @data
    
    @precisionFormat = d3.format(".2f")
      
    @x = d3.scale.ordinal()
              .rangeRoundBands([0, @width], .1)

    @y = d3.scale.linear()
              .range([@height, 0])

    @yAxis = d3.svg.axis()
                    .scale(@y)
                    .orient("left")
                    
    @svg = d3.select("#difference").append("svg")
                  .attr("width", @width + @margin.left + @margin.right)
                  .attr("height", @height + @margin.top + @margin.bottom)
                .append("g")
                  .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
                  
  #Given the avg and actual value, just compute the difference    
  computeDifference: (d) =>
    if @indicator == 'National' then (d.avg_total_payments - d.weighted_mean_payments) else (d.avg_total_payments - d.state_avg_total_payments)
    
  computeChargesDifference: (d) =>
    if @indicator == 'National' then (d.avg_covered_charges - d.weighted_mean_charges) else (d.avg_covered_charges - d.state_avg_covered_charges)
                  
  #Behavior when mouse is over bar
  mouseOver: (d) =>
    friendlyDefn = d.drg_definition.split(" - ")[1]
    $("#drg-name").text(friendlyDefn)
    diff = @precisionFormat(@computeDifference(d))
    if diff > 0
      diff = "+" + diff
    suffix = if @indicator == 'National' then 'Nationally' else 'State wide'
    payments = "$" + @precisionFormat(d.avg_total_payments) + " (" + diff + ") " + suffix
    $("#drg-payments").val(payments)
    chargesDiff = @precisionFormat(@computeChargesDifference(d))
    if chargesDiff > 0
      chargesDiff = "+" + chargesDiff
    charges = "$" + @precisionFormat(d.avg_covered_charges) + " (" + chargesDiff + ") " + suffix
    $("#drg-charges").val(charges)
    $("#drg-discharges-count").val(d.total_discharges)
    $("#drg-state-payments").val("$" + @precisionFormat(d.state_avg_total_payments))
    $("#drg-national-payments").val("$" + @precisionFormat(d.weighted_mean_payments))
    
  update: (indicator) ->
    @indicator = indicator
    
    #Transition axes and bars 
    @y.domain(d3.extent(@data.charges, @computeDifference)).nice()
    t1 = @svg.transition().duration(750)
    t1.select(".x.axis line")
          .attr("y1", @y(0))
          .attr("y2", @y(0))
          
    t1.select(".y.axis").call(@yAxis)
    t1.selectAll(".bar")
        .attr("class", (d) => if @computeDifference(d) < 0 then 'bar negative' else 'bar positive')
        .attr("y", (d) => @y(Math.max(0, @computeDifference(d))) )
        .attr("height", (d) => Math.abs(@y(1) - @y(@computeDifference(d))) )
    @updateInfo()
          
  
  updateInfo: () ->
    d3.select("#p-name").text(@data.name + " (" + @data.city + ", " + @data.state_code + ")")
    $("#p-drg-count").val(@data.charges.length)
    aboveCount = 0
    belowCount = 0
    that = @
    @data.charges.map (d) -> 
      if that.computeDifference(d) > 0
        aboveCount += 1
      else
        belowCount += 1
    $("#p-above-payments").val(aboveCount)
    $("#p-below-payments").val(belowCount)
      
    
  renderWithSelection: (data, drg) ->
    @render(data)
    s = null
    data.charges.map (d) ->
      if (d.drg_id == drg) 
        s = d
    @mouseOver(s)
    selected = @svg.select("#drg-" + drg)
    selected.style("stroke-width", 1.0)

  render: (data) ->
    @data = data
    @updateInfo()
    @x.domain(@data.charges.map((d) -> d.id ))
    @y.domain(d3.extent(@data.charges, @computeDifference)).nice()
    
    that = @
    
    @svg.append("text")
      .attr("transform", "translate(340, 520)" + "rotate(0)")
      .text("Diagnostic Related Group(DRG)")
    
    @svg.select(".x.axis").remove()
    @svg.append("g")
      .attr("class", "x axis")
    .append("line")
      .attr("x2", @width)
      .attr("y1", @y(0))
      .attr("y2", @y(0))
      .style("stroke-width", 0.5)
      

    

    @svg.select(".y.axis").remove()
    @svg.append("g")
        .attr("class", "y axis")
        .call(@yAxis)
      .append("text")
        .attr("transform", "translate(-60," + 380 + ")" + "rotate(-90)")
        #.attr("transform", "rotate(-90)")
        .text("Difference with Weighted Average Payments Nationally")

    @svg.selectAll(".bar").remove()
    @svg.selectAll(".bar")
        .data(@data.charges)
      .enter().append("rect")
        .attr("class", "bar")
        .attr("id", (d) -> "drg-" + d.drg_id)
        .attr("class", (d) => if @computeDifference(d) < 0 then 'bar negative' else 'bar positive')
        .attr("x", (d) => @x(d.id) )
        .attr("width", @x.rangeBand())
        .attr("y", (d) => @y(Math.max(0, @computeDifference(d))) )
        .attr("height", (d) => Math.abs(@y(1) - @y(@computeDifference(d))) )
        .on("mouseover", (d) -> 
          d3.selectAll(".bar").style("stroke-width", 0)
          d3.select(this).style("stroke-width", 1.0)
          that.mouseOver(d)
        )
  
    
    

#Some globals
geoChart = null
drgs = []
container = new HexContainer('#chart')
barChart = new BarChart()
first = null
second = null

$ ->
  $(".dropdown-menu").on("click", "li a", (e) ->
    $target = $(e.currentTarget)
    id = $target.data('id')
    $(".icon-spinner").show()
    meanPayments = $target.data('payments')
    meanCharges = $target.data('charges')
    name = $target.text()
    $("#select-msg").text(name)
    container.meanPayments = meanPayments
    container.meanCharges = meanCharges
    d3.json "/providers/inpatient_charges.json?id=" + id, renderContainer
  )
  
  $("#comparator").on("click", "a", (e) ->
    e.preventDefault()
    $target = $(e.currentTarget)
    if (barChart.indicator != $target.html()) 
      $("#comparator a").toggleClass("active btn-success")
      barChart.update($target.html())
  )


storeDrgs = (error, data) ->
  drgs = data
  data.forEach (d) ->
    friendlyDefn = d.definition.split(" - ")[1]
    elem = "<li><a data-id=" + d.id + " data-payments=" + d.weighted_mean_payments + " data-charges=" + d.weighted_mean_charges + " href=#>" + friendlyDefn + "</a></li>"
    $(".dropdown-menu").append(elem)
  

renderMap = (error, data) ->
  geoChart = new GeoChart(data, '#map', barChart)
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
  $(".icon-spinner").hide()
  
# $ ->
d3.json "/providers/drgs.json", storeDrgs
  
    
d3.json "us-named.json", renderMap



