class ProvidersController < ApplicationController

  def index
    @providers = Provider.all
    #@providers = Provider.limit(10)
    render :json => @providers.to_json(:methods => [:total_payments])
  end
  
  def provider_ids
    @providers = Provider.all.map{|p| {id: p.id, value: p.name} }
    render :json => @providers.to_json
  end
  
  def states
    @states = State.all
    render :json => @states.to_json(:methods => [:total_payments, :std_deviation_payments, :std_deviation_charges, :std_deviation_discharges, :count], :root => false)
  end
  
  #Show provider
  def show
    #TODO: fix with 1 charge/drg only, eg; 5866
    @provider = Provider.where(:id => params[:id]).includes([:inpatient_charges]).first
    render json: @provider
  end
  
  def drgs
    drgs = DiagnosticRelatedGroup.all
    render :json => drgs.to_json(:only => [:definition, :id, :weighted_mean_payments, :weighted_mean_charges], :root => false)
  end
  
  def inpatient_charges
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

end
