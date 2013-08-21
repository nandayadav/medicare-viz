require 'opta/parser'
require 'opta/event'
class ProvidersController < ApplicationController
  include Rega::Charts
  
  
  def index
    @providers = Provider.all
    #@providers = Provider.limit(10)
    render :json => @providers.to_json(:methods => [:total_payments])
  end
  
  def states
    @states = State.all
    render :json => @states.to_json(:methods => [:total_payments, :std_deviation_payments, :std_deviation_charges, :std_deviation_discharges, :count], :root => false)
  end
  
  #Show provider
  def show
    @provider = Provider.where(:id => params[:id]).includes([:inpatient_charges]).first
    render json: @provider
  end
  
  def drgs
    drgs = DiagnosticRelatedGroup.all
    render :json => drgs.to_json(:only => [:definition, :id], :root => false)
  end
  
  def inpatient_charges
    drg_id = DiagnosticRelatedGroup.find params[:id].to_i
    charges = InpatientCharge.where(:diagnostic_related_group_id => drg_id, :state_id => nil).includes([:diagnostic_related_group, :provider])#.select([:provider_id, :avg_total_payments, :avg_covered_charges])
    #render :json => charges.to_json(:root => false, :include => :provider, :methods => [:state_code])
    render :json => charges.to_json(:root => false)
  end
  
  def inpatient_charges_new
    drg_id = DiagnosticRelatedGroup.find params[:id].to_i
    charges = InpatientCharge.where(:diagnostic_related_group_id => drg_id, :state_id => nil).includes([:diagnostic_related_group, :provider])
    #render :json => charges.to_json(:root => false, :include => :provider, :methods => [:state_code])
    render :json => charges, :root => false
  end
  
  def drg_stats
    #{drg: '123', std_deviation: 34.3}
    drg = DiagnosticRelatedGroup.all
    render :json => drg.to_json(:methods => [:std_deviation, :count], :root => false)
  end
  
  def bar_chart
    chart = Bar.new(url: '/providers/drg_stats', x: 'definition', y: 'std_deviation')
    c = chart.generate do |config|
      config.width = 1000
    end
    render :json => c.to_json
  end
  
  def opta
    events, result = [], []
    %w(first).each do |f|
      p = Opta::Parser.new("#{f}.xml")
      events += p.events.map{|e| Opta::Event.new(e)}
    end
    events.each do |event|
      type_id = event.type_id
      # next unless event.period_id == 1
      next unless event.team_id == 810
      #next unless type_id == 13
      x = event.x.to_f
      y = event.y.to_f
      #next unless event.team_id == 810
      next if x < 0.0 || y < 0.0 || x > 100.0 || y > 100.0
      next if x == 0.0 && y == 0.0
      result << {:x => x, :y => y}
    end
    render :json => result.to_json
  end
end
